#pragma once
#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include <algorithm>

USING_YOSYS_NAMESPACE

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

    std::string t = cell->type.str();
    if (!t.empty() && (t[0] == '\\' || t[0] == '$')) t = t.substr(1);
    for (auto &c : t) c = std::tolower((unsigned char)c);
    if (t.size() >= 4 && t.substr(0, 3) == "lut") {
        bool ok = true;
        for (size_t i = 3; i < t.size(); i++)
            if (!std::isdigit((unsigned char)t[i])) { ok = false; break; }
        if (ok) return true;
    }
    return false;
}

static bool is_buffer(Cell *cell)
{
    if (cell->type == ID($_BUF_)) return true;
    if (cell->type == ID($lut) && cell->getParam(ID::WIDTH).as_int() == 1)
        return cell->getParam(ID::LUT).as_int() == 2;
    return false;
}

static bool is_control_port_name(IdString port)
{
    std::string p = port.str();
    if (!p.empty() && (p[0] == '\\' || p[0] == '$')) p = p.substr(1);
    for (auto &c : p) c = std::tolower((unsigned char)c);
    static const pool<std::string> ctrl = {
        "r", "rst", "reset", "resetn", "nreset",
        "areset", "aresetn", "sreset", "sresetn",
        "s", "set", "setn", "nset", "aset", "asetn", "sset",
        "clr", "clrn", "clear", "aclr", "sclr",
        "e", "en", "ce", "enable", "load"
    };
    return ctrl.count(p) > 0;
}

// Driver map + depth over ALL non-sequential cells (for path analysis).
struct CombGraph {
    dict<SigBit, Cell*> driver;
    pool<SigBit>        sources; // FF Q-outputs + module PIs
    dict<Cell*, int>    depth;

    void build(Module *module, Design *design,
               const pool<RTLIL::Wire*> &clocks, SigMap &sigmap)
    {
        for (auto cell : module->selected_cells()) {
            if (cell_is_sequential(cell, design)) {
                for (auto &conn : cell->connections())
                    if (cell->output(conn.first))
                        for (auto bit : sigmap(conn.second))
                            if (bit.wire) sources.insert(bit);
                continue;
            }
            for (auto &conn : cell->connections())
                if (cell->output(conn.first))
                    for (auto bit : sigmap(conn.second))
                        if (bit.wire) driver[bit] = cell;
        }
        for (auto wire : module->wires())
            if (wire->port_input)
                for (auto bit : sigmap(SigSpec(wire)))
                    sources.insert(bit);

        std::function<int(Cell*)> cell_depth = [&](Cell *cell) -> int {
            auto it = depth.find(cell);
            if (it != depth.end()) return it->second;
            depth[cell] = -1;
            int mx = 0;
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second)) {
                    if (!bit.wire || clocks.count(bit.wire)) continue;
                    if (sources.count(bit)) continue;
                    auto dit = driver.find(bit);
                    if (dit == driver.end()) continue;
                    if (depth.count(dit->second) && depth.at(dit->second) == -1) continue;
                    mx = std::max(mx, cell_depth(dit->second));
                }
            }
            depth[cell] = mx + 1;
            return depth[cell];
        };
        for (auto cell : module->selected_cells())
            if (!cell_is_sequential(cell, design))
                cell_depth(cell);
    }
};
