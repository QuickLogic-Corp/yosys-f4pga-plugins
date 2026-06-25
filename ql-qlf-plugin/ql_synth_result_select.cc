#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include "design_analysis_utils.h"
#include <fstream>
#include <regex>
#include <vector>
#include <cmath>
#include <limits>
#include <algorithm>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct DesignCandidate {
    std::string name;
    int nd;
    int lev;
};

static std::pair<int, int> extract_abc_metrics(const std::string &fname)
{
    std::ifstream f(fname);
    if (!f.is_open())
        return {-1, -1};

    std::regex re(R"(nd\s*=\s*([0-9]+).*lev\s*=\s*([0-9]+))");
    std::string line;
    while (std::getline(f, line)) {
        std::smatch m;
        if (std::regex_search(line, m, re))
            return {std::stoi(m[1].str()), std::stoi(m[2].str())};
    }
    return {-1, -1};
}

static bool check_equivalence(const std::string &fname)
{
    std::ifstream f(fname);
    if (!f.is_open())
        return false;

    std::string line;
    while (std::getline(f, line)) {
        std::string lower = line;
        for (auto &c : lower) c = std::tolower((unsigned char)c);
        if (lower.find("networks are equivalent") != std::string::npos)
            return true;
    }
    return false;
}

static std::string pick_best_design(const std::vector<DesignCandidate> &cands,
                                    const std::string &mode)
{
    if (cands.empty()) return "";
    if (cands.size() == 1) return cands[0].name;

    // Check if all candidates are identical
    bool all_equal = true;
    for (size_t i = 1; i < cands.size(); i++)
        if (cands[i].nd != cands[0].nd || cands[i].lev != cands[0].lev)
            { all_equal = false; break; }
    if (all_equal) {
        log("synth_result_select: all candidates have identical metrics, using '%s'.\n",
            cands[0].name.c_str());
        return cands[0].name;
    }

    if (mode == "delay") {
        return std::min_element(cands.begin(), cands.end(),
            [](const DesignCandidate &a, const DesignCandidate &b) {
                return a.lev != b.lev ? a.lev < b.lev : a.nd < b.nd;
            })->name;
    }

    if (mode == "area") {
        return std::min_element(cands.begin(), cands.end(),
            [](const DesignCandidate &a, const DesignCandidate &b) {
                return a.nd != b.nd ? a.nd < b.nd : a.lev < b.lev;
            })->name;
    }

    // mixed -- normalised combined score
    int dmin = std::min_element(cands.begin(), cands.end(),
                   [](const DesignCandidate &a, const DesignCandidate &b){ return a.lev < b.lev; })->lev;
    int dmax = std::max_element(cands.begin(), cands.end(),
                   [](const DesignCandidate &a, const DesignCandidate &b){ return a.lev < b.lev; })->lev;
    int amin = std::min_element(cands.begin(), cands.end(),
                   [](const DesignCandidate &a, const DesignCandidate &b){ return a.nd < b.nd; })->nd;
    int amax = std::max_element(cands.begin(), cands.end(),
                   [](const DesignCandidate &a, const DesignCandidate &b){ return a.nd < b.nd; })->nd;

    std::string best_name = cands[0].name;
    double best_score = std::numeric_limits<double>::max();

    for (const auto &c : cands) {
        double D = (dmax == dmin) ? 0.0 : double(c.lev - dmin) / (dmax - dmin);
        double A = (amax == amin) ? 0.0 :
                   (std::log(double(c.nd)) - std::log(double(amin))) /
                   (std::log(double(amax)) - std::log(double(amin)));
        double score = 0.5 * A + 0.5 * D;
        if (score < best_score) { best_score = score; best_name = c.name; }
    }
    return best_name;
}

struct SynthResultSelectPass : public Pass {
    SynthResultSelectPass() : Pass("synth_result_select",
        "run synthesis flows and select the best result") {}

    void help() override
    {
        log("\n");
        log("    synth_result_select [options]\n");
        log("\n");
        log("Runs one or more synthesis flows (lut6, delay-exploration,\n");
        log("area-exploration, mixed-exploration, synplify) and loads the design\n");
        log("that best meets the chosen objective.\n");
        log("\n");
        log("    -de <delay|area|mixed>\n");
        log("        Enable design exploration with the given objective.\n");
        log("        Default: delay\n");
        log("\n");
        log("    -synplify\n");
        log("        Also run the Synplify-compatible flow and include its result\n");
        log("        in the comparison.\n");
        log("\n");
        log("    -family_path <path>\n");
        log("        Path prefix for technology map files (required with -synplify).\n");
        log("\n");
        log("    -family <name>\n");
        log("        Family subdirectory used when locating synplify_map.v.\n");
        log("\n");
        log("    -top <N>\n");
        log("        Number of paths/nets to print in report_paths and report_fanout.\n");
        log("        Default: 10\n");
        log("\n");
        log("    -write_blif\n");
        log("        Write a BLIF file for each flow (lut6.blif, de.blif, synplify.blif).\n");
        log("        Off by default.\n");
        log("\n");
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        log_header(design, "Executing SYNTH_RESULT_SELECT pass.\n");

        std::string de         = "delay";
        bool        synplify   = false;
        std::string lib_path;
        std::string family;
        int         top        = 10;
        bool        write_blif = false;

        size_t argidx = 1;
        for (; argidx < args.size(); argidx++) {
            if (args[argidx] == "-de" && argidx + 1 < args.size()) {
                de = args[++argidx];
                if (de != "delay" && de != "area" && de != "mixed")
                    log_error("synth_result_select: -de must be delay, area, or mixed.\n");
            } else if (args[argidx] == "-synplify") {
                synplify = true;
            } else if (args[argidx] == "-family_path" && argidx + 1 < args.size()) {
                lib_path = args[++argidx];
            } else if (args[argidx] == "-family" && argidx + 1 < args.size()) {
                family = args[++argidx];
            } else if (args[argidx] == "-top" && argidx + 1 < args.size()) {
                top = std::atoi(args[++argidx].c_str());
            } else if (args[argidx] == "-write_blif") {
                write_blif = true;
            } else {
                break;
            }
        }
        extra_args(args, argidx, design);

        if (synplify && (lib_path.empty() || family.empty()))
            log_error("synth_result_select: -family_path and -family are required with -synplify.\n");

        std::string top_arg = " -top " + std::to_string(top);

        // ---- synplify flow (optional) ------------------------------------
        if (synplify) {
            Pass::call(design, "report_paths" + top_arg + " -o synplify_paths.rpt");
            Pass::call(design, "report_fanout" + top_arg + " -o synplify_fanout.rpt");
            Pass::call(design, "design -save synplify");
            std::string family_map = " " + lib_path + family;
            Pass::call(design, "techmap -map" + family_map + "/synplify_map.v");
            Pass::call(design, "tee -o synplify_abc_stat.log abc_stats");
            if (write_blif) Pass::call(design, "write_blif synplify.blif");

            Pass::call(design, "design -load synplify");
            Pass::call(design, "flatten");
            Pass::call(design, "techmap -map" + family_map + "/synplify_map.v");
            Pass::call(design, "techmap");
        }

        // ---- save base for reproducible reruns ---------------------------
        Pass::call(design, "design -save base");

        // ---- lut6 flow ---------------------------------------------------
        Pass::call(design, "design -load base");
        Pass::call(design, "tee -o abc_lut6.log abc -script +/quicklogic/abc_scripts/lut6.scr");
        Pass::call(design, "abc_stats");
        Pass::call(design, "report_paths" + top_arg + " -o lut6_paths.rpt");
        Pass::call(design, "report_fanout" + top_arg + " -o lut6_fanout.rpt");
        Pass::call(design, "design -save lut6");
        if (write_blif) Pass::call(design, "write_blif lut6.blif");
        auto [lut6_nd, lut6_lev] = extract_abc_metrics("abc_lut6.log");

        // ---- design-exploration flow -------------------------------------
        Pass::call(design, "design -load base");
        if      (de == "delay") Pass::call(design, "tee -o abc_de.log abc -script +/quicklogic/abc_scripts/dde.scr");
        else if (de == "area")  Pass::call(design, "tee -o abc_de.log abc -script +/quicklogic/abc_scripts/ade.scr");
        else                    Pass::call(design, "tee -o abc_de.log abc -script +/quicklogic/abc_scripts/mde.scr");
        Pass::call(design, "abc_stats");
        Pass::call(design, "report_paths" + top_arg + " -o de_paths.rpt");
        Pass::call(design, "report_fanout" + top_arg + " -o de_fanout.rpt");
        Pass::call(design, "design -save de");
        if (write_blif) Pass::call(design, "write_blif de.blif");

        // ---- build candidate list ----------------------------------------
        std::vector<DesignCandidate> candidates;
        candidates.push_back({"lut6", lut6_nd, lut6_lev});

        if (!check_equivalence("abc_de.log")) {
            log("Networks are not Equivalent after DE -- excluding DE from comparison.\n");
        } else {
            log("Networks are Equivalent after DE.\n");
            auto [de_nd, de_lev] = extract_abc_metrics("abc_de.log");
            candidates.push_back({"de", de_nd, de_lev});
        }

        if (synplify) {
            auto [syn_nd, syn_lev] = extract_abc_metrics("synplify_abc_stat.log");
            if (syn_nd < 0)
                log_warning("synth_result_select: could not parse synplify_abc_stat.log -- excluding synplify from comparison.\n");
            else
                candidates.push_back({"synplify", syn_nd, syn_lev});
        }

        // ---- log comparison table ----------------------------------------
        log("\n");
        log("  %-12s  %8s  %8s\n", "design", "nd", "lev");
        log("  %-12s  %8s  %8s\n", "------", "---", "---");
        for (const auto &c : candidates)
            log("  %-12s  %8d  %8d\n", c.name.c_str(), c.nd, c.lev);
        log("\n");

        // ---- pick and load winner ----------------------------------------
        std::string best = pick_best_design(candidates, de);
        Pass::call(design, "design -load " + best);
        log("synth_result_select: using '%s' (objective: %s).\n", best.c_str(), de.c_str());
    }
} SynthResultSelectPass;

PRIVATE_NAMESPACE_END
