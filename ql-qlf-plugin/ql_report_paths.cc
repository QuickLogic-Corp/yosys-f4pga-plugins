// report_paths -- reports the top-N critical combinational paths (src -> dest, depth)
#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include "design_analysis_utils.h"
#include <fstream>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct ReportPathsPass : public Pass {
    ReportPathsPass() : Pass("report_paths", "report top-N critical paths through all combinational cells") {}

    void help() override
    {
        log("\n");
        log("    report_paths [-top <N>] [-o <file>] [selection]\n");
        log("\n");
        log("Print the top N critical paths through ALL combinational cells\n");
        log("(including adder_carry, BRAMs, etc.), matching PnR timing paths.\n");
        log("Sources are FF Q-outputs and primary inputs.\n");
        log("Sinks are FF D-inputs and primary outputs.\n");
        log("Control-port sinks (reset, enable, set, clear, ...) are excluded.\n");
        log("\n");
        log("    -top <N>    Number of paths to print (default: 10).\n");
        log("    -o <file>   Write output to file instead of log.\n");
        log("\n");
    }

    void execute(std::vector<std::string> args, Design *design) override
    {
        int top = 10;
        std::string outfile;
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-top" && argidx + 1 < args.size()) {
                top = std::atoi(args[++argidx].c_str()); continue;
            }
            if (args[argidx] == "-o" && argidx + 1 < args.size()) {
                outfile = args[++argidx]; continue;
            }
            break;
        }
        extra_args(args, argidx, design);
        log_header(design, "Executing REPORT_PATHS pass.\n");

        std::ofstream ofs;
        if (!outfile.empty()) {
            ofs.open(outfile);
            if (!ofs.is_open())
                log_error("report_paths: cannot open output file '%s'.\n", outfile.c_str());
        }

        for (auto module : design->selected_modules())
            run_module(module, design, top, ofs);
    }

    void run_module(Module *module, Design *design, int top, std::ofstream &ofs)
    {
        auto out = [&](const std::string &s) {
            if (ofs.is_open()) ofs << s;
            else               log("%s", s.c_str());
        };

        SigMap sigmap(module);
        auto clocks = find_clock_wires(module);

        CombGraph g;
        g.build(module, design, clocks, sigmap);

        // Collect data sinks: non-control FF inputs + primary outputs
        std::vector<std::pair<int, std::pair<SigBit, std::string>>> sinks;

        for (auto cell : module->selected_cells()) {
            if (!cell_is_sequential(cell, design)) continue;
            RTLIL::Module *lib_mod = design->module(cell->type);
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                if (is_control_port_name(conn.first)) continue;
                if (lib_mod) {
                    RTLIL::Wire *p = lib_mod->wire(conn.first);
                    if (p && p->get_bool_attribute(ID::clkbuf_sink)) continue;
                }
                for (auto bit : sigmap(conn.second)) {
                    if (!bit.wire) continue;
                    auto dit = g.driver.find(bit);
                    if (dit == g.driver.end()) continue;
                    std::string label = std::string(log_id(cell->name)) +
                                        " (" + log_id(cell->type) + ") ." +
                                        log_id(conn.first);
                    sinks.push_back({g.depth.at(dit->second), {bit, label}});
                }
            }
        }
        for (auto wire : module->wires()) {
            if (!wire->port_output) continue;
            for (auto bit : sigmap(SigSpec(wire))) {
                auto dit = g.driver.find(bit);
                if (dit == g.driver.end()) continue;
                sinks.push_back({g.depth.at(dit->second),
                                 {bit, std::string("PO:") + log_id(wire)}});
            }
        }
        std::sort(sinks.rbegin(), sinks.rend());

        auto collect_sinks = [&](SigBit bit) -> std::vector<std::string> {
            std::vector<std::string> res;
            for (auto cell : module->cells())
                for (auto &conn : cell->connections()) {
                    if (!cell->input(conn.first)) continue;
                    for (auto b : sigmap(conn.second))
                        if (b == bit)
                            res.push_back(std::string(log_id(cell->name)) +
                                          " (" + log_id(cell->type) + ") ." +
                                          log_id(conn.first));
                }
            return res;
        };

        if (sinks.empty()) {
            out("\nNo combinational data paths found.\n");
            out("  All outputs are driven directly by sequential cells or\n");
            out("  all combinational paths lead only to control ports (reset/enable/...).\n\n");
            return;
        }

        int count = 0;
        for (auto &[d, p] : sinks) {
            if (count >= top) break;
            auto &[sink_bit, sink_label] = p;

            struct PathNode { SigBit bit; Cell *cell; int depth; };
            std::vector<PathNode> path_nodes;

            SigBit cur = sink_bit;
            while (true) {
                auto dit = g.driver.find(cur);
                if (dit == g.driver.end()) {
                    path_nodes.push_back({cur, nullptr, 0});
                    break;
                }
                Cell *cell = dit->second;
                path_nodes.push_back({cur, cell, g.depth.at(cell)});

                int best_d = -2;
                SigBit best_bit;
                for (auto &conn : cell->connections()) {
                    if (!cell->input(conn.first)) continue;
                    for (auto bit : sigmap(conn.second)) {
                        if (!bit.wire || clocks.count(bit.wire)) continue;
                        int bd = g.sources.count(bit) ? -1
                               : [&]() {
                                     auto d2 = g.driver.find(bit);
                                     return d2 == g.driver.end() ? -1 : g.depth.at(d2->second);
                                 }();
                        if (bd > best_d) { best_d = bd; best_bit = bit; }
                    }
                }
                if (best_d == -2) break;
                cur = best_bit;
                if (g.sources.count(cur)) {
                    path_nodes.push_back({cur, nullptr, 0});
                    break;
                }
            }

            std::reverse(path_nodes.begin(), path_nodes.end());
            out("\nCritical path #" + std::to_string(++count) +
                "  depth=" + std::to_string(d) +
                "  endpoint: " + sink_label + "\n");

            for (size_t i = 0; i < path_nodes.size(); i++) {
                auto &node = path_nodes[i];
                if (node.cell == nullptr) {
                    out("  [src] " + std::string(log_signal(node.bit)) + "\n");
                } else {
                    out("  [" + std::to_string(node.depth) + "] " +
                        std::string(log_signal(node.bit)) + "\n");
                    out("         -> " + std::string(log_id(node.cell->name)) +
                        " (" + std::string(log_id(node.cell->type)) + ")\n");
                }
                if (i == path_nodes.size() - 1 && node.cell != nullptr) {
                    for (auto &s : collect_sinks(node.bit))
                        out("         -> " + s + "\n");
                }
            }
        }
        out("\n");
    }
} ReportPathsPass;

PRIVATE_NAMESPACE_END
