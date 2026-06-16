#include "kernel/yosys.h"
#include "kernel/sigtools.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// -----------------------------------------------------------------------
// Library-aware helpers
// -----------------------------------------------------------------------

static bool cell_is_sequential(Cell *cell, Design *design)
{
    RTLIL::Module *lib_mod = design->module(cell->type);
    if (!lib_mod) return false;
    for (auto &conn : cell->connections()) {
        RTLIL::Wire *port = lib_mod->wire(conn.first);
        if (port && port->get_bool_attribute(ID::clkbuf_sink))
            return true;
    }
    return false;
}

static pool<RTLIL::Wire*> find_clock_wires(RTLIL::Module *mod)
{
    pool<RTLIL::Wire*> clocks;
    for (auto cell : mod->cells()) {
        RTLIL::Module *lib_mod = mod->design->module(cell->type);
        if (!lib_mod) continue;
        for (auto &conn : cell->connections()) {
            RTLIL::Wire *port = lib_mod->wire(conn.first);
            if (!port || !port->get_bool_attribute(ID::clkbuf_sink)) continue;
            for (auto &bit : conn.second)
                if (bit.wire) clocks.insert(bit.wire);
        }
    }
    return clocks;
}

// Native combinational cells — the only cells that count as nd.
// Matches:
//   - Yosys internal primitives ($lut, $_NOT_, $_AND_, ...)
//   - Library LUT cells by name (LUT1..LUT6, lut1..lut6)
//     ABC knows LUT truth tables from liberty so it expands them to .names;
//     all other library cells (adder_carry, BRAMs, ...) stay as .subckt black boxes.
static bool is_native_comb(Cell *cell)
{
    if (cell->type.in(
            ID($lut),
            ID($_BUF_),  ID($_NOT_),
            ID($_AND_),  ID($_NAND_), ID($_OR_),   ID($_NOR_),
            ID($_XOR_),  ID($_XNOR_),
            ID($_ANDNOT_), ID($_ORNOT_),
            ID($_MUX_),  ID($_NMUX_),
            ID($_AOI3_), ID($_OAI3_), ID($_AOI4_), ID($_OAI4_),
            ID($_TBUF_)))
        return true;

    // Library LUT cells: strip leading \ or $, lowercase, match lut\d+
    std::string t = cell->type.str();
    if (!t.empty() && (t[0] == '\\' || t[0] == '$')) t = t.substr(1);
    for (auto &c : t) c = std::tolower((unsigned char)c);
    if (t.size() >= 4 && t.substr(0, 3) == "lut") {
        bool all_digits = true;
        for (size_t i = 3; i < t.size(); i++)
            if (!std::isdigit((unsigned char)t[i])) { all_digits = false; break; }
        if (all_digits) return true;
    }
    return false;
}

static bool is_buffer(Cell *cell)
{
    if (cell->type == ID($_BUF_)) return true;
    // $lut width=1 with pass-through table (0b10 = output follows input)
    if (cell->type == ID($lut) && cell->getParam(ID::WIDTH).as_int() == 1)
        return cell->getParam(ID::LUT).as_int() == 2;
    // Library LUT1 cells are inverters or buffers — ABC counts them as nd either way,
    // so do NOT treat them as buffers here.
    return false;
}

// -----------------------------------------------------------------------
// Pass
// -----------------------------------------------------------------------
struct AbcStatsPass : public Pass {
    AbcStatsPass() : Pass("abc_stats", "print ABC-equivalent netlist statistics") {}

    void help() override
    {
        log("\n");
        log("    abc_stats [-debug] [selection]\n");
        log("\n");
        log("Print statistics matching ABC 'print_stats':\n");
        log("\n");
        log("    netlist : i/o = <in>/<out>  lat = <lat>  nd = <nd>"
            "  edge = <edge>  lev = <lev>\n");
        log("\n");
        log("Matches ABC's black-box model: only $lut/$_*_ primitive cells\n");
        log("(from BLIF .names) count as nd.  All other cells are opaque.\n");
        log("i/o counts only signals crossing the native-comb cone boundary.\n");
        log("Sequential cells detected via clkbuf_sink on loaded library ports.\n");
        log("\n");
        log("    -debug\n");
        log("        Print per-cell classification and per-bit cone boundary.\n");
        log("\n");
    }

    void execute(std::vector<std::string> args, Design *design) override
    {
        bool debug = false;
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-debug") { debug = true; continue; }
            break;
        }
        extra_args(args, argidx, design);

        for (auto module : design->selected_modules())
            run_module(module, design, debug);
    }

    void run_module(Module *module, Design *design, bool debug)
    {
        SigMap sigmap(module);
        auto clocks = find_clock_wires(module);

        if (debug) {
            log("[abc_stats] module: %s\n", log_id(module));
            log("[abc_stats] clock wires:");
            for (auto w : clocks) log(" %s", log_id(w));
            log("\n");
        }

        // -------------------------------------------------------------------
        // Pass 1: classify cells, build comb-driver map
        // -------------------------------------------------------------------
        int n_lat = 0, n_nd = 0;
        dict<SigBit, Cell*> comb_driver;

        for (auto cell : module->selected_cells()) {
            if (cell_is_sequential(cell, design)) {
                n_lat++;
                if (debug)
                    log("[abc_stats]   SEQ  %s (%s)\n",
                        log_id(cell), log_id(cell->type));
                continue;
            }
            if (is_native_comb(cell)) {
                bool buf = is_buffer(cell);
                if (!buf) n_nd++;
                if (debug)
                    log("[abc_stats]   %s %s (%s)\n",
                        buf ? "BUF " : "COMB", log_id(cell), log_id(cell->type));
                for (auto &conn : cell->connections())
                    if (cell->output(conn.first))
                        for (auto bit : sigmap(conn.second))
                            comb_driver[bit] = cell;
                continue;
            }
            if (debug)
                log("[abc_stats]   BBOX %s (%s)\n",
                    log_id(cell), log_id(cell->type));
        }

        // -------------------------------------------------------------------
        // Pass 2: cone boundary
        //   cone_in  = bits entering native comb NOT produced by native comb
        //   cone_out = bits leaving native comb to PO or non-native sink
        // -------------------------------------------------------------------
        pool<SigBit> cone_in_bits;
        pool<SigBit> cone_out_bits;

        // fanout: comb-driven bit → non-native cells that consume it
        pool<SigBit> consumed_by_nonnative;
        for (auto cell : module->selected_cells()) {
            if (is_native_comb(cell)) continue;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second))
                    if (comb_driver.count(bit))
                        consumed_by_nonnative.insert(bit);
            }
        }

        for (auto cell : module->selected_cells()) {
            if (!is_native_comb(cell)) continue;
            for (auto &conn : cell->connections()) {
                if (cell->input(conn.first)) {
                    for (auto bit : sigmap(conn.second)) {
                        if (!bit.wire || clocks.count(bit.wire)) continue;
                        if (!comb_driver.count(bit))
                            cone_in_bits.insert(bit);
                    }
                } else {
                    for (auto bit : sigmap(conn.second)) {
                        if (!bit.wire) continue;
                        if (bit.wire->port_output || consumed_by_nonnative.count(bit))
                            cone_out_bits.insert(bit);
                    }
                }
            }
        }

        if (debug) {
            log("[abc_stats] cone inputs  (%d):\n", (int)cone_in_bits.size());
            for (auto &b : cone_in_bits)
                log("[abc_stats]   %s\n", log_signal(b));
            log("[abc_stats] cone outputs (%d):\n", (int)cone_out_bits.size());
            for (auto &b : cone_out_bits)
                log("[abc_stats]   %s\n", log_signal(b));
        }

        // -------------------------------------------------------------------
        // Pass 3: edges (every non-clock input bit of non-buffer native cells)
        // -------------------------------------------------------------------
        int n_edge = 0;
        for (auto cell : module->selected_cells()) {
            if (!is_native_comb(cell) || is_buffer(cell)) continue;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second))
                    if (bit.wire && !clocks.count(bit.wire))
                        n_edge++;
            }
        }

        // -------------------------------------------------------------------
        // Pass 4: depth DP through native comb cells
        // -------------------------------------------------------------------
        dict<Cell*, int> depth;
        std::function<int(Cell*)> cell_depth = [&](Cell *cell) -> int {
            auto it = depth.find(cell);
            if (it != depth.end()) return it->second;
            depth[cell] = -1;
            int mx = 0;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second)) {
                    if (cone_in_bits.count(bit))  continue; // depth-0 source
                    if (clocks.count(bit.wire))   continue;
                    auto dit = comb_driver.find(bit);
                    if (dit == comb_driver.end()) continue;
                    if (depth.count(dit->second) && depth.at(dit->second) == -1) continue;
                    mx = std::max(mx, cell_depth(dit->second));
                }
            }
            depth[cell] = mx + 1;
            return depth[cell];
        };
        for (auto cell : module->selected_cells())
            if (is_native_comb(cell)) cell_depth(cell);

        int max_lev = 0;
        for (auto bit : cone_out_bits) {
            auto dit = comb_driver.find(bit);
            if (dit != comb_driver.end()) {
                int d = depth.at(dit->second);
                if (debug)
                    log("[abc_stats] cone_out %s  depth=%d\n", log_signal(bit), d);
                max_lev = std::max(max_lev, d);
            }
        }

        log("ABC: netlist                       : "
            "i/o = %4d/%4d  lat = %4d  nd = %6d  edge = %7d  lev = %d\n",
            (int)cone_in_bits.size(), (int)cone_out_bits.size(),
            n_lat, n_nd, n_edge, max_lev);
    }
} AbcStatsPass;

PRIVATE_NAMESPACE_END
