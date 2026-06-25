// report_fanout -- reports the top-N high-fanout nets with per-net sink list and histogram
#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include "design_analysis_utils.h"
#include <fstream>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct ReportFanoutPass : public Pass {
    ReportFanoutPass() : Pass("report_fanout", "report top-N high-fanout nets") {}

    void help() override
    {
        log("\n");
        log("    report_fanout [-top <N>] [-o <file>] [selection]\n");
        log("\n");
        log("Print the top N nets by fanout. Clock nets are excluded.\n");
        log("Nets with the same fanout as the Nth net are all reported.\n");
        log("A fanout distribution histogram is printed at the end.\n");
        log("\n");
        log("    -top <N>    Number of nets to print (default: 10).\n");
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
        log_header(design, "Executing REPORT_FANOUT pass.\n");

        std::ofstream ofs;
        if (!outfile.empty()) {
            ofs.open(outfile);
            if (!ofs.is_open())
                log_error("report_fanout: cannot open output file '%s'.\n", outfile.c_str());
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

        dict<SigBit, Cell*> comb_driver;
        for (auto cell : module->selected_cells()) {
            if (!is_native_comb(cell)) continue;
            for (auto &conn : cell->connections())
                if (cell->output(conn.first))
                    for (auto bit : sigmap(conn.second))
                        comb_driver[bit] = cell;
        }

        dict<SigBit, int> fanout;
        dict<SigBit, std::vector<std::tuple<std::string,std::string,std::string>>> bit_sinks;
        for (auto cell : module->selected_cells()) {
            for (auto &conn : cell->connections()) {
                if (!cell->input(conn.first)) continue;
                for (auto bit : sigmap(conn.second)) {
                    if (!bit.wire) continue;
                    fanout[bit]++;
                    bit_sinks[bit].push_back({
                        log_id(cell->name),
                        log_id(cell->type),
                        log_id(conn.first)
                    });
                }
            }
        }

        std::vector<std::pair<int, SigBit>> nets;
        for (auto &[bit, cnt] : fanout) {
            if (clocks.count(bit.wire)) continue;
            nets.push_back({cnt, bit});
        }
        std::sort(nets.rbegin(), nets.rend());

        dict<int, int> fanout_hist;
        for (auto &[cnt, bit] : nets) fanout_hist[cnt]++;

        out("\nHigh-fanout nets (top " + std::to_string(top) +
            ", " + std::to_string((int)nets.size()) + " unique nets after filtering):\n");

        int count = 0;
        int cutoff_fanout = -1;
        for (auto &[cnt, bit] : nets) {
            if (count >= top && cnt != cutoff_fanout) break;
            if (count == top - 1) cutoff_fanout = cnt;

            std::string src;
            if (bit.wire->port_input)
                src = "PI";
            else if (comb_driver.count(bit))
                src = std::string("COMB:") + log_id(comb_driver.at(bit)->type);
            else
                src = "BBOX";

            char buf[256];
            std::snprintf(buf, sizeof(buf), "  #%-3d fanout=%-5d  [%s]  %s\n",
                ++count, cnt, src.c_str(), log_signal(bit));
            out(buf);

            if (bit_sinks.count(bit))
                for (auto &[cname, ctype, port] : bit_sinks.at(bit))
                    out("         -> " + cname + " (" + ctype + ") ." + port + "\n");
        }

        std::vector<std::pair<int,int>> hist_sorted(fanout_hist.begin(), fanout_hist.end());
        std::sort(hist_sorted.rbegin(), hist_sorted.rend());
        out("\n  Fanout distribution:\n");
        for (auto &[f, n] : hist_sorted) {
            char buf[128];
            std::snprintf(buf, sizeof(buf), "    fanout=%-5d  %d net%s\n", f, n, n == 1 ? "" : "s");
            out(buf);
        }
        out("\n");
    }
} ReportFanoutPass;

PRIVATE_NAMESPACE_END
