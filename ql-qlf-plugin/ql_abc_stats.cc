// abc_stats -- prints ABC-equivalent netlist statistics (i/o, lat, nd, edge, lev)
#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include "design_analysis_utils.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

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
        log("    -debug    Per-cell classification and cone boundary bits.\n");
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
        log_header(design, "Executing ABC_STATS pass.\n");
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

        int n_lat = 0, n_nd = 0;
        dict<SigBit, Cell*> comb_driver;

        for (auto cell : module->selected_cells()) {
            if (cell_is_sequential(cell, design)) {
                n_lat++;
                if (debug) log("[abc_stats]   SEQ  %s (%s)\n", log_id(cell), log_id(cell->type));
                continue;
            }
            if (is_native_comb(cell)) {
                bool buf = is_buffer(cell);
                if (!buf) n_nd++;
                if (debug) log("[abc_stats]   %s %s (%s)\n",
                    buf ? "BUF " : "COMB", log_id(cell), log_id(cell->type));
                for (auto &conn : cell->connections())
                    if (cell->output(conn.first))
                        for (auto bit : sigmap(conn.second))
                            comb_driver[bit] = cell;
                continue;
            }
            if (debug) log("[abc_stats]   BBOX %s (%s)\n", log_id(cell), log_id(cell->type));
        }

        pool<SigBit> consumed_by_nonnative;
        for (auto cell : module->selected_cells()) {
            if (is_native_comb(cell)) continue;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second))
                    if (comb_driver.count(bit)) consumed_by_nonnative.insert(bit);
            }
        }

        pool<SigBit> cone_in, cone_out;
        for (auto cell : module->selected_cells()) {
            if (!is_native_comb(cell)) continue;
            for (auto &conn : cell->connections()) {
                if (cell->input(conn.first)) {
                    for (auto bit : sigmap(conn.second)) {
                        if (!bit.wire || clocks.count(bit.wire)) continue;
                        if (!comb_driver.count(bit)) cone_in.insert(bit);
                    }
                } else {
                    for (auto bit : sigmap(conn.second)) {
                        if (!bit.wire) continue;
                        if (bit.wire->port_output || consumed_by_nonnative.count(bit))
                            cone_out.insert(bit);
                    }
                }
            }
        }

        if (debug) {
            log("[abc_stats] cone inputs  (%d):\n", (int)cone_in.size());
            for (auto &b : cone_in)  log("[abc_stats]   %s\n", log_signal(b));
            log("[abc_stats] cone outputs (%d):\n", (int)cone_out.size());
            for (auto &b : cone_out) log("[abc_stats]   %s\n", log_signal(b));
        }

        int n_edge = 0;
        for (auto cell : module->selected_cells()) {
            if (!is_native_comb(cell) || is_buffer(cell)) continue;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second))
                    if (bit.wire && !clocks.count(bit.wire)) n_edge++;
            }
        }

        dict<Cell*, int> depth;
        std::function<int(Cell*)> cell_depth = [&](Cell *cell) -> int {
            auto it = depth.find(cell);
            if (it != depth.end()) return it->second;
            depth[cell] = -1;
            int mx = 0;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second)) {
                    if (cone_in.count(bit) || clocks.count(bit.wire)) continue;
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
        for (auto bit : cone_out) {
            auto dit = comb_driver.find(bit);
            if (dit != comb_driver.end())
                max_lev = std::max(max_lev, depth.at(dit->second));
        }

        log("ABC: netlist                       : "
            "i/o = %4d/%4d  lat = %4d  nd = %6d  edge = %7d  lev = %d\n",
            (int)cone_in.size(), (int)cone_out.size(),
            n_lat, n_nd, n_edge, max_lev);
    }
} AbcStatsPass;

PRIVATE_NAMESPACE_END
