/*
 * Copyright 2020-2022 F4PGA Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 */
#include "kernel/celltypes.h"
#include "kernel/log.h"
#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/sigtools.h"
#include <cmath>
#include <fstream>
#include <sstream>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// All .model names of a BLIF file, in order (first = the IP module itself;
// any later ones are embedded blackbox primitive definitions, present only if
// the file was written with -blackbox). Used by -rel_ip_blif
// to find and remove already-present empty blackbox definitions (the IP's
// stub, or a primitive another IP file also embeds) before read_blif, which
// would otherwise error on the duplicate.
//
// This is the second BLIF .model parser of the relative-placement flow; the
// other one is parse_model_output_ports() in
// aurora2/scripts/rel_macro_placement/rel_macro_blif_common.py. Keep the two
// in agreement about what a .model line looks like.
static std::vector<std::string> rel_ip_model_names(const std::string &filename)
{
    std::ifstream f(filename);
    if (!f.is_open())
        log_error("-rel_ip_blif: cannot open '%s'\n", filename.c_str());
    std::vector<std::string> names;
    std::string line;
    while (std::getline(f, line)) {
        size_t pos = line.find_first_not_of(" \t\r");
        if (pos == std::string::npos || line.compare(pos, 6, ".model") != 0)
            continue;
        // The name may be separated from the keyword by any run of blanks, not
        // just one space: taking ".model " literally silently skips a
        // tab-separated line, and a later .model would then be mistaken for the
        // IP module itself.
        size_t name_pos = pos + 6;
        if (name_pos < line.size() && line[name_pos] != ' ' && line[name_pos] != '\t')
            continue;
        std::istringstream ss(line.substr(name_pos));
        std::string name;
        ss >> name;
        if (!name.empty())
            names.push_back(name);
    }
    return names;
}

#define XSTR(val) #val
#define STR(val) XSTR(val)

#ifndef PASS_NAME
#define PASS_NAME synth_quicklogic
#endif

/* This function extracts abc metrics (lev(delay logic level) 
    and nd(number of luts) from the abc log.)*/

std::pair<int, int> extract_abc_metrics(const std::string &fname) 
{
    std::ifstream f(fname);
    std::string line;

    std::regex re(R"(nd\s*=\s*([0-9]+).*lev\s*=\s*([0-9]+))");

    while (std::getline(f, line)) {
        std::smatch m;
        if (std::regex_search(line, m, re)) {
            int nd  = std::stoi(m[1].str());
            int lev = std::stoi(m[2].str());
            return {nd, lev};
        }
    }

    return {-1, -1};
}


bool check_equivalence(const std::string& fname)
{
    std::ifstream f(fname);
    if (!f.is_open())
        return false;  

    std::string line;
    while (std::getline(f, line)) {
        if (line.find("Networks are equivalent.") != std::string::npos)
            return true;
    }

    return false;
}


struct SynthQuickLogicPass : public ScriptPass {

    SynthQuickLogicPass() : ScriptPass(STR(PASS_NAME), "Synthesis for QuickLogic FPGAs") {}

    void help() override
    {
        log("\n");
        log("   %s [options]\n", STR(PASS_NAME));
        log("This command runs synthesis for QuickLogic FPGAs\n");
        log("\n");
        log("    -top <module>\n");
        log("         use the specified module as top module\n");
        log("\n");
        log("    -family <family>\n");
        log("        run synthesis for the specified QuickLogic architecture\n");
        log("        generate the synthesis netlist for the specified family.\n");
        log("        supported values:\n");
        log("        - pp3\n");
        log("        - qlf_k4n8\n");
        log("        - qlf_k6n10\n");
        log("        - qlf_k6n10f\n");
        log("    -lib_path <lib_path>\n");
        log("        Specify the library files directory (device data)\n");
        log("\n");
        log("    -no_abc_opt\n");
        log("        By default most of ABC logic optimization features is\n");
        log("        enabled. Specifying this switch turns them off.\n");
        log("\n");
        log("    -custom_abc_script\n");
        log("        This path specifies the custom ABC script passing to Yosys.\n");
        log("        The default Yosys script for ABC will be running if this parameter is not specified.\n");
        log("\n");
        log("    -edif <file>\n");
        log("        write the design to the specified edif file. Writing of an output file\n");
        log("        is omitted if this parameter is not specified.\n");
        log("\n");
        log("    -blif <file>\n");
        log("        write the design to the specified BLIF file. Writing of an output file\n");
        log("        is omitted if this parameter is not specified.\n");
        log("\n");
        log("    -rel_ip_blif <file>\n");
        log("        link the given pre-synthesized IP netlist (extended BLIF carrying\n");
        log("        relative-placement .attr annotations) into the design right before\n");
        log("        the -blif output is written, then flatten. The IP module must be\n");
        log("        undefined or an empty blackbox stub at that point. May be given\n");
        log("        multiple times. See docs/development/relative_macro_placement/.\n");
        log("\n");
        log("    -clocks_file <file>\n");
        log("        write the design clock nets to the specified clocks file. If not passed\n");
        log("        top module name will be used as the clocks file name.\n");
        log("\n");
        log("    -verilog <file>\n");
        log("        write the design to the specified verilog file. Writing of an output\n");
        log("        file is omitted if this parameter is not specified.\n");
        log("\n");
        log("    -no_dsp\n");
        log("        By default use DSP blocks in output netlist.\n");
        log("        do not use DSP blocks to implement multipliers and associated logic\n");
        log("\n");
        log("    -use_dsp_cfg_params\n");
        log("        By default use DSP blocks with configuration bits available at module\n");
        log("        ports. Specifying this forces usage of DSP block with configuration\n");
        log("        bits available as module parameters.\n");
        log("\n");
        log("    -no_adder\n");
        log("        By default use adder cells in output netlist.\n");
        log("        Specifying this switch turns it off.\n");
        log("\n");
        log("    -no_bram\n");
        log("        By default use Block RAM in output netlist.\n");
        log("        Specifying this switch turns it off.\n");
        log("\n");
        log("    -bram_types\n");
        log("        Emit specialized BRAM cells for particular address and data width\n");
        log("        configurations.\n");
        log("\n");
        log("    -no_ff_map\n");
        log("        By default ff techmap is turned on. Specifying this switch turns it off.\n");
        log("\n");
        log("    -nosdff\n");
        log("        By default infer synchronous S/R flip-flops for architectures that\n");
        log("        support them. Specifying this switch turns it off.\n");
        log("\n");
        log("    -no_ffenable\n");
        log("        By default infer flip-flops with enable for architectures that\n");
        log("        support them. Specifying this switch infer flip-flops without enable.\n");
        log("\n");
        log("    -mince_num <number>\n");
        log("        By default infer flip-flops with enable for architectures that\n");
        log("        support them. Specifying this switch infer flip-flops enable only if its greater than mince_num <number> value.\n");
        log("\n");
        log("    -ioff\n");
        log("        By default flip-flops in the IO is not used for the designs that\n");
        log("        are feasible. Specifying this will force synthesis to use IOFFs.\n");
        log("        Requires a GPIO v3.0 architecture when the promoted registers carry a\n");
        log("        reset, since those become io_sdffr/io_sdffnr cells.\n");
        log("\n");
        log("    -bramecc\n");
        log("        By default use BRAM without ECC support for designs \n");
        log("        Specifying this will use BRAM with ECC support.\n");
        log("\n");
        log("    -dspv2\n");
        log("        By default use dsp version1 support for designs \n");
        log("        Specifying this will use dsp version2 support.\n");
        log("\n");
        log("    -dspv4\n");
        log("        Target the DSP version4 (DSP-V4) hard block. On the -synplify\n");
        log("        flow this converts the QL_DSPV2 cells Synplify infers into\n");
        log("        generic monolithic QL_DSP4 base cells (runs ql_dspv2_to_dspv4 in place\n");
        log("        of ql_dspv2_types). Phase-1 scope.\n");
        log("\n");
        log("    -no_tdpram\n");
        log("        By default infer TDP BRAM for architectures that support them.\n");
        log("        Specifying this switch infer SDP BRAM only.\n");
        log("\n");
        log("    -noopt\n");
        log("        By default all optimizations are turned on. \n");
        log("        Specifying this switch turns off all optimizations and only maps the design.\n");
        log("\n");
        log("    -synplify\n");
        log("        synplify description \n");
        log("\n");
        log("    -de\n");
        log("        uses de for deeper optimizations. Use area, delay, mixed as the optimization approach \n");
        log("\n");
        log("\n");
        log("The following commands are executed by this synthesis command:\n");
        help_script();
        log("\n");
    }

    string top_opt, edif_file, blif_file, clocks_file, family, currmodule, verilog_file, use_dsp_cfg_params, lib_path, mince_num, custom_abc_script, de;
    bool nodsp;
    bool inferAdder;
    bool inferBram;
    bool bramTypes;
    bool abcOpt;
    bool abc9;
    bool noffmap;
    bool nosdff;
    bool noffenable; 
    bool ioff;
	bool bramecc;
	bool dspv2;
	bool dspv4;
    bool notdpram;
    bool noOpt;
    bool synplify;
    std::vector<std::string> rel_ip_blif_files;

    void clear_flags() override
    {
        custom_abc_script = "";
        top_opt = "-auto-top";
        edif_file = "";
        blif_file = "";
        verilog_file = "";
        clocks_file = "";
        currmodule = "";
        family = "qlf_k4n8";
        inferAdder = true;
        inferBram = true;
        bramTypes = false;
        abcOpt = true;
        abc9 = true;
        noffmap = false;
        nodsp = false;
        nosdff = false;
        noffenable = false;
        ioff = false;
		bramecc = false;
		dspv2 = false;
		dspv4 = false;
        notdpram = false;
        noOpt = false;
        synplify = false;
        use_dsp_cfg_params = "";
        lib_path = "+/quicklogic/";
        mince_num = "";
        de = "";
        rel_ip_blif_files.clear();
    }

    pool<RTLIL::Wire*> find_clock_wires(RTLIL::Module *mod)
    {
        pool<RTLIL::Wire*> clock_wires;
        SigMap sigmap(mod);

        for (auto cell : mod->cells()) {
            for (auto &conn : cell->connections()) {
                // look up the cell definition in the design
                RTLIL::Module *cell_mod = mod->design->module(cell->type);
                if (!cell_mod)
                    continue;

                // get the port wire in the cell's own module
                RTLIL::Wire *cell_port = cell_mod->wire(conn.first);
                if (!cell_port)
                    continue;

                if (!cell_port->get_bool_attribute(ID::clkbuf_sink))
                    continue;

                // Grab the wires connected to this port in the parent module,
                // canonicalized through the sigmap. techmap gives every hard-block
                // port its own local alias wire (e.g. $techmapNNNN\<inst>.CLK_A2_i),
                // so one clock net reaches N BRAM ports as N distinct Wire* objects.
                // pool<> dedupes pointer-identical wires but cannot collapse aliases,
                // so inserting bit.wire raw makes the .clocks file list one clock per
                // BRAM port; downstream floorplanning then spends a global clock pin
                // on each and rejects the real design clock once the 4 pins are gone.
                for (auto &bit : conn.second) {
                    if (!bit.wire)
                        continue;

                    RTLIL::SigBit canonical = sigmap(bit);
                    if (!canonical.wire)
                        continue; // clkbuf_sink tied to a constant

                    log("Found clock wire: %s (via clkbuf_sink on cell %s port %s)\n",
                        log_id(canonical.wire->name),
                        log_id(cell->name),
                        log_id(conn.first));

                    clock_wires.insert(canonical.wire);
                }
            }
        }

        return clock_wires;
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        string run_from, run_to;
        clear_flags();
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-run" && argidx + 1 < args.size()) {
                size_t pos = args[argidx + 1].find(':');
                if (pos == std::string::npos) {
                    run_from = args[++argidx];
                    run_to = args[argidx];
                } else {
                    run_from = args[++argidx].substr(0, pos);
                    run_to = args[argidx].substr(pos + 1);
                }
                continue;
            }
            if (args[argidx] == "-top" && argidx + 1 < args.size()) {
                top_opt = "-top " + args[++argidx];
                continue;
            }
            if (args[argidx] == "-edif" && argidx + 1 < args.size()) {
                edif_file = args[++argidx];
                continue;
            }

            if (args[argidx] == "-family" && argidx + 1 < args.size()) {
                family = args[++argidx];
                continue;
            }
            if (args[argidx] == "-lib_path" && argidx + 1 < args.size()) {
                lib_path = args[++argidx];
                continue;
            }
            if (args[argidx] == "-rel_ip_blif" && argidx + 1 < args.size()) {
                rel_ip_blif_files.push_back(args[++argidx]);
                continue;
            }
            if (args[argidx] == "-blif" && argidx + 1 < args.size()) {
                blif_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-verilog" && argidx + 1 < args.size()) {
                verilog_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-clocks_file" && argidx + 1 < args.size()) {
                clocks_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-no_dsp") {
                nodsp = true;
                continue;
            }
            if (args[argidx] == "-use_dsp_cfg_params") {
                use_dsp_cfg_params = " -use_dsp_cfg_params";
                continue;
            }
            if (args[argidx] == "-no_adder") {
                inferAdder = false;
                continue;
            }
            if (args[argidx] == "-no_bram") {
                inferBram = false;
                continue;
            }
            if (args[argidx] == "-bram_types") {
                bramTypes = true;
                continue;
            }
            if (args[argidx] == "-no_abc_opt") {
                abcOpt = false;
                continue;
            }
            if (args[argidx] == "-no_abc9") {
                abc9 = false;
                continue;
            }
            if (args[argidx] == "-custom_abc_script" && argidx + 1 < args.size()) {
                custom_abc_script = args[++argidx];
                continue;
            }
            if (args[argidx] == "-no_ff_map") {
                noffmap = true;
                continue;
            }
            if (args[argidx] == "-nosdff") {
                nosdff = true;
                continue;
            }
            if (args[argidx] == "-no_ffenable") {
                noffenable = true;
                continue;
            }
            if (args[argidx] == "-mince_num" && argidx + 1 < args.size()) {
                mince_num = args[++argidx];
                continue;
            }
            if (args[argidx] == "-ioff") {
                ioff = true;
                continue;
            }
            if (args[argidx] == "-bramecc") {
                bramecc = true;
                continue;
            } 
            if (args[argidx] == "-dspv2") {
                dspv2 = true;
                continue;
            }
            if (args[argidx] == "-dspv4") {
                dspv4 = true;
                continue;
            }
            if (args[argidx] == "-no_tdpram") {
                notdpram = true;
                continue;
            }
            if (args[argidx] == "-no_opt") {
                noOpt = true;
                abcOpt = false;
                continue;
            }
            if (args[argidx] == "-synplify") {
                synplify = true;
                continue;
            }
            if (args[argidx] == "-de" && argidx + 1 < args.size()) {
                de = args[++argidx];
                continue;
            }

            break;
        }
        if(lib_path == "+/quicklogic/")
            lib_path = design->scratchpad_get_string("ql.lib_path", lib_path);
        extra_args(args, argidx, design);

        if (!design->full_selection())
            log_cmd_error("This command only operates on fully selected designs!\n");

        if (family != "pp3" && family != "qlf_k4n8" && family != "qlf_k6n10" && family != "qlf_k6n10f")
            log_cmd_error("Invalid family specified: '%s'\n", family.c_str());

        // DSP-V4 reaches hardware two ways, and both end at the same techmap:
        //   -dspv4 -synplify : Synplify infers QL_DSPV2, ql_dspv2_to_dspv4
        //                      converts, dsp4_logical_map.v lowers.
        //   -dspv4           : ql_dspv4 infers QL_DSP4 from RTL directly,
        //                      dsp4_logical_map.v lowers.
        // Until Phase 2 the second had no implementation and was refused here.

        if (family == "qlf_k4n8") {
            nosdff = true;
        }

        if (abc9 && design->scratchpad_get_int("abc9.D", 0) == 0) {
            log_warning("delay target has not been set via SDC or scratchpad; assuming 12 MHz clock.\n");
            if (family == "pp3") {
                design->scratchpad_set_int("abc9.D", 41666); // 12MHz = 83.33.. ns; divided by two to allow for interconnect delay.
            }
            if (family == "qlf_k6n10f") {
                design->scratchpad_set_int("abc9.W", 1000); // set interconnet delay as 1ns
            }
        }

        log_header(design, "Executing SYNTH_QUICKLOGIC pass.\n");
        log_push();

        run_script(design, run_from, run_to);

        log_pop();
    }

    void script() override
    {
        if (help_mode) {
            family = "<family>";
        }

        std::string noDFFArgs;
        if (check_label("begin")) {
            std::string family_path = " " + lib_path + family;
            std::string readVelArgs;

            // Read simulation library
            readVelArgs = family_path + "/cells_sim.v";
            if (family == "qlf_k6n10f") {
                // DSP behavioural models from family_path (device_data). The V4
                // conversion consumes QL_DSPV2 cells (defined in dspv2_sim.v, the
                // same input model the V2 flow reads) and emits QL_DSP4, so the V4
                // path reads both the V2 input model and the V4 model.
                if (dspv4)
                    readVelArgs += family_path + "/dspv2_sim.v" + family_path + "/dspv4_sim.v";
                else
                    readVelArgs += family_path + (dspv2 ? "/dspv2_sim.v" : "/dsp_sim.v");
                if(inferBram) {
                    readVelArgs += family_path + "/brams_sim.v";
                    if (bramTypes) {
                        readVelArgs += family_path + "/bram_types_sim.v";
                    }
                }
                if (synplify) {
                    readVelArgs += family_path + "/synplify_map.v";
					readVelArgs += family_path + "/synplify_bram_map.v";
                }
            }
            // Use -nomem2reg here to prevent Yosys from complaining about
            // some block ram cell models. After all the only part of the cells
            // library required here is cell port definitions plus specify blocks.
            run("read_verilog -lib -specify -nomem2reg " + readVelArgs);
			if (synplify && !dspv2 && !dspv4) {
			    // Full behavioural QL_DSPV2.v is only used by the dspv2->dspv1
			    // translation path.
			    run("read_verilog " + family_path + "/QL_DSPV2.v");
			}
			if (dspv4 && family == "qlf_k6n10f") {
			    // V4 path: read the QL_DSP4 base-cell primitive (the conversion
			    // output). The QL_DSPV2 input interface comes from dspv2_sim.v and
			    // QL_DSP4's behavioural body (dsp4_top) from dspv4_sim.v, both read
			    // above. QL_DSPV2.v itself is not needed on this path.
			    run("read_verilog -lib -specify -nomem2reg" + family_path + "/QL_DSP4.v");
			    // Phase-2 dsp4_logical leaf primitives (QL_DSP4_MULT / _ALU_* /
			    // _PREADD|PRESUB / _RSS / bit-sliced *_DFFR[E]). The decompose
			    // techmap (map_dsp) rewrites QL_DSP4 into these; read as black
			    // boxes so they carry through to write_blif for VPR packing.
			    run("read_verilog -lib -specify -nomem2reg" + family_path + "/QL_DSP4_leaves.v");
			}
            run(stringf("hierarchy -check %s", help_mode ? "-top <top>" : top_opt.c_str()));
        }

        if (check_label("prepare")) {
            if (synplify) {
				// As early as possible: synplify_map.v expands IBUF_FF/OBUF_FF into
				// a plain dff, and it is techmapped in more than one place -- the
				// map_luts label does so before ABC whenever -de is set, well ahead
				// of map_synplify. Translating here, straight off the front end,
				// means the cells are consumed while they still exist regardless of
				// which of those paths the run takes. On a v3.0 architecture the dff
				// they would otherwise become has no model and packing fails with
				// "Subckt instantiates model 'dff'".
				run("ql_io_translate");
				run("proc");
				run("flatten");
				run("opt -nodffe -nosdff");
				run("fsm");
				run("wreduce");
				run("peepopt");
				run("opt_clean");
				run("share");
            }
            else{
			    run("proc");
                run("flatten");
                if (help_mode || family == "pp3") {
                    run("tribuf -logic", "                   (for pp3)");
                }
                run("deminout");
                if (!noOpt) {
                    run("opt_expr");
                    run("opt_clean");
                }

                if (nosdff) {
                    noDFFArgs += " -nosdff";
                }
                if (family == "qlf_k4n8") {
                    noDFFArgs += " -nodffe";
                }

                run("check");
                if (!noOpt) {
                    run("opt -nodffe -nosdff");
                    run("fsm");
                    run("opt" + noDFFArgs);
                    run("wreduce");
                    run("peepopt");
                    run("opt_clean");
                    run("share");
                }
            }
        }

        if (check_label("map_dsp"), "(skip if -no_dsp)") {
            if (help_mode || family == "qlf_k6n10") {
                if (help_mode || !nodsp) {
                    run("memory_dff", "                      (for qlf_k6n10)");
                    if (!noOpt) {
                        run("wreduce t:$mul", "                  (for qlf_k6n10)");
                    }
                    run("techmap -map +/mul2dsp.v -map " + lib_path + family +
                          "/dsp_map.v -D DSP_A_MAXWIDTH=16 -D DSP_B_MAXWIDTH=16 "
                          "-D DSP_A_MINWIDTH=2 -D DSP_B_MINWIDTH=2 -D DSP_Y_MINWIDTH=11 "
                          "-D DSP_NAME=$__MUL16X16",
                        "    (for qlf_k6n10)");
                    run("select a:mul2dsp", "                (for qlf_k6n10)");
                    run("setattr -unset mul2dsp", "          (for qlf_k6n10)");
                    if (!noOpt) {
                        run("opt_expr -fine", "                  (for qlf_k6n10)");
                        run("wreduce", "                         (for qlf_k6n10)");
                    }
                    run("select -clear", "                   (for qlf_k6n10)");
                    run("ql_dspv1", "                        (for qlf_k6n10)");
                    run("chtype -set $mul t:$__soft_mul", "  (for qlf_k6n10)");
                }
            }
            if (help_mode || family == "qlf_k6n10f") {			

                struct DspParams {
                    size_t a_maxwidth;
                    size_t b_maxwidth;
                    size_t a_minwidth;
                    size_t b_minwidth;
                    std::string type;
                };

                const std::vector<DspParams> dsp_rules = {
                  {20, 18, 11, 10, "$__QL_MUL20X18"},
                  {10, 9, 2, 2, "$__QL_MUL10X9"},
                };

                if (help_mode) {
                    run("wreduce t:$mul", "                  (for qlf_k6n10f)");
                    run("ql_dsp_macc" + use_dsp_cfg_params, "(for qlf_k6n10f)");
                    run("techmap -map +/mul2dsp.v [...]", "  (for qlf_k6n10f)");
                    run("chtype -set $mul t:$__soft_mul", "  (for qlf_k6n10f)");
                    run("techmap -map " + lib_path + family + "/dsp_map.v", "(for qlf_k6n10f)");
                    if (use_dsp_cfg_params.empty())
                        run("techmap -map " + lib_path + family + "/dsp_map.v -D USE_DSP_CFG_PARAMS=0", "(for qlf_k6n10f)");
                    else
                        run("techmap -map " + lib_path + family + "/dsp_map.v -D USE_DSP_CFG_PARAMS=1", "(for qlf_k6n10f)");
                    run("ql_dsp_simd", "                     (for qlf_k6n10f)");
                    run("techmap -map " + lib_path + family + "/dsp_final_map.v", "(for qlf_k6n10f)");
                    run("ql_dsp_io_regs", "                  (for qlf_k6n10f)");
                } else if (!nodsp) {

                    run("wreduce t:$mul");

                    if (dspv2 || dspv4) {
                        // The block below is the *V2* inference chain: it turns $mul
                        // into QL_DSPV2 cells via mul2dsp + dsp_map.v / dsp_final_map.v.
                        // Those two files are V1/V2 device collateral -- a DSP-V4
                        // device ships dspv4_sim.v instead and legitimately has
                        // neither, so running this on the V4 path hard-errors with
                        // "dsp_map.v not found".
                        //
                        // V4 does not need them. The Synplify path arrives with
                        // QL_DSPV2 cells already inferred and only needs
                        // ql_dspv2_to_dspv4 + dsp4_logical_map.v; the non-Synplify
                        // path infers QL_DSP4 directly via ql_dspv4 below. Neither
                        // reads dsp_map.v, so neither trips the missing-file error.
                        if (!synplify && dspv4) {
                            // Native V4 inference (Phase 2). Emits QL_DSP4 cells
                            // with their control word already set; the techmap
                            // below lowers them exactly as it does the cells the
                            // Synplify bridge produces, so the two routes cannot
                            // drift apart.
                            //
                            // Multiplies the DSP cannot hold stay as $mul for the
                            // ordinary soft path, each named by a log_debug (IN-7).
                            run("ql_dspv4");
                        }
                        if (!synplify && !dspv4) {
                            // DSPv2 arm — ported from YosysHQ/yosys#4932
                            // (povik/ql-dspv2 @ c68fd85b9ccceb773a4aaac2a35f7d90fbb15fc8).
                            // Uses wider 32x18 and 16x9 multiplier shapes via mul2dsp +
                            // dsp_map.v techmap, followed by MULTACC inference via
                            // ql_dsp_macc.
                            //
                            // Scope for this release (per PR #52 review): support is
                            // limited to basic MULT (and MULTACC via ql_dsp_macc).
                            // The cascade/register-packing pass (ql_dspv2), SIMD
                            // packing (ql_dsp_simd) and IO-register packing
                            // (ql_dsp_io_regs) are intentionally commented out and
                            // deferred to a follow-up. Keeping them as commented
                            // call sites preserves the #4932 pipeline shape for
                            // easy re-enable.
                            //
                            // Device-data convention (Aurora `device_data` submodule):
                            // V1 and V2 devices ship their cell library under the
                            // same filenames (`dsp_sim.v`, `dsp_map.v`,
                            // `dsp_final_map.v`); the per-device file content selects
                            // V1 vs V2 behaviour. We therefore reference the same
                            // filenames on both arms here.
                            run("ql_dsp_macc -dspv2");
                            run("techmap -map +/mul2dsp.v -map " + lib_path + family + "/dsp_map.v "
                                "-D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY "
                                "-D DSP_A_MAXWIDTH=32 -D DSP_B_MAXWIDTH=18 "
                                "-D DSP_A_MINWIDTH=10 -D DSP_B_MINWIDTH=10 "
                                "-D DSP_NAME=$__QL_MUL32X18");
                            run("chtype -set $mul t:$__soft_mul");
                            run("techmap -map +/mul2dsp.v -map " + lib_path + family + "/dsp_map.v "
                                "-D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY "
                                "-D DSP_A_MAXWIDTH=16 -D DSP_B_MAXWIDTH=9 "
                                "-D DSP_A_MINWIDTH=4 -D DSP_B_MINWIDTH=4 "
                                "-D DSP_NAME=$__QL_MUL16X9");
                            run("chtype -set $mul t:$__soft_mul");
                            // Deferred for this release — see comment above.
                            // run("ql_dspv2");
                            // run("ql_dsp_simd");
                            run("techmap -map " + lib_path + family + "/dsp_final_map.v");
                            // run("ql_dsp_io_regs");
                            // Converts generic QL_DSPV2 cells emitted above into
                            // mode-specific subtypes (QL_DSPV2_MULT/MULTACC/MULTADD
                            // with REGIN/REGOUT variants). Only meaningful on the V2
                            // path — V1 designs never produce QL_DSPV2 cells.
                        }
                        if (dspv4) {
                            // V4 path: convert the generic QL_DSPV2 cells into
                            // monolithic QL_DSP4 base cells (per-cell + cascade-pair
                            // fusion) in place of the V2 mode-subtype specialization.
                            run("ql_dspv2_to_dspv4");
                            // Last point where the control word is still readable as
                            // parameters, and where every producer's cells are
                            // present: inference, the bridge above, the macro library
                            // and direct instantiation. Warn here about configurations
                            // whose arithmetic wraps silently.
                            run("ql_dsp4_check");
                            // Phase 2: decompose each monolithic QL_DSP4 into the
                            // dsp4_logical operating-mode leaf cells (mult / alu /
                            // pre-adder / rss / bit-sliced registers) so the netlist
                            // packs onto the DSPV4 tile. Pure Verilog techmap.
                            run("techmap -map " + lib_path + family + "/dsp4_logical_map.v");
                            run("opt_clean -purge");
                        } else {
                            run("ql_dspv2_types");
                        }
                    } else {
                        run("ql_dsp_macc" + use_dsp_cfg_params);

                        for (const auto &rule : dsp_rules) {
                            run(stringf("techmap -map +/mul2dsp.v "
                                        "-D DSP_A_MAXWIDTH=%zu -D DSP_B_MAXWIDTH=%zu "
                                        "-D DSP_A_MINWIDTH=%zu -D DSP_B_MINWIDTH=%zu "
                                        "-D DSP_NAME=%s",
                                        rule.a_maxwidth, rule.b_maxwidth, rule.a_minwidth, rule.b_minwidth, rule.type.c_str()));
                            run("chtype -set $mul t:$__soft_mul");
                        }
                        if (use_dsp_cfg_params.empty())
                            run("techmap -map " + lib_path + family + "/dsp_map.v -D USE_DSP_CFG_PARAMS=0");
                        else
                            run("techmap -map " + lib_path + family + "/dsp_map.v -D USE_DSP_CFG_PARAMS=1");
                        run("ql_dsp_simd");
                        run("techmap -map " + lib_path + family + "/dsp_final_map.v");
                        run("ql_dsp_io_regs");
                    }
                }
            }
        }

        if (check_label("coarse")) {
            //if (!synplify) {
                run("techmap -map +/cmp2lut.v -D LUT_WIDTH=4");
                if (!noOpt) {
                    run("opt_expr");
                    run("opt_clean");
                }
                run("alumacc");
                run("pmuxtree");
                if (!noOpt) {
                    run("opt" + noDFFArgs);
                }
                run("memory -nomap");
                if (!noOpt) {
                    run("opt_clean");
                }
            //}
        }

        if (check_label("map_bram", "(skip if -no_bram)") && (help_mode || family == "qlf_k6n10" || family == "qlf_k6n10f" || family == "pp3") &&
            inferBram) {
            if (help_mode || family == "qlf_k6n10f") {
				if (synplify) {
					run("techmap -autoproc -map " + lib_path + family + "/synplify_bram_map.v");
				}
                if (notdpram) {
                    run("memory_libmap -lib " + lib_path + family + "/libmap_brams_sdp.txt", "(for qlf_k6n10f)");
                    run("ql_sdpbram_merge", "(for qlf_k6n10f)");
                    run("techmap -map " + lib_path + family + "/libmap_brams_map_sdp.v", "(for qlf_k6n10f)");
                } else {
                    run("memory_libmap -lib " + lib_path + family + "/libmap_brams_tdp.txt", "(for qlf_k6n10f)");
                    run("ql_tdpbram_merge", "(for qlf_k6n10f)");
                    run("techmap -map " + lib_path + family + "/libmap_brams_map_tdp.v", "(for qlf_k6n10f)");
                }
            }
            if (help_mode || family == "qlf_k6n10" || family == "pp3") {
                run("memory_bram -rules " + lib_path + family + "/brams.txt", "(for pp3, qlf_k6n10)");
            }
            if (help_mode || family == "pp3") {
                run("pp3_braminit", "(for pp3)");
            }
            run("techmap -autoproc -map " + lib_path + family + "/brams_map.v");
            if (family == "qlf_k6n10f") {
                run("techmap -map " + lib_path + family + "/brams_final_map.v");
            }

            if (bramTypes || help_mode) {
				if (bramecc) {
					if (notdpram) {
						run("ql_sdp_bramecc_types", "(if -bramtypes)"); 
					} else {
						run("ql_bramecc_types", "(if -bramtypes)");
					}
			    } else {
					if (notdpram) {
						run("ql_sdp_bram_types", "(if -bramtypes)");
					} else {
						run("ql_bram_types", "(if -bramtypes)");
					}
				}
            }
        }

        if (check_label("map_ffram")) {
            if (!synplify) {
                if (!noOpt) {
                    run("opt -fast -mux_undef -undriven -fine" + noDFFArgs);
                }
                run("memory_map -iattr -attr !ram_block -attr !rom_block -attr logic_block "
                    "-attr syn_ramstyle=auto -attr syn_ramstyle=registers "
                    "-attr syn_romstyle=auto -attr syn_romstyle=logic");
                if (!noOpt) {
                    run("opt -undriven -fine" + noDFFArgs);
                }
            }
        }

        if (check_label("map_gates")) {
            //if (!synplify) {
                if (help_mode || (inferAdder && (family == "qlf_k4n8" || family == "qlf_k6n10" || family == "qlf_k6n10f"))) {
                    run("techmap -map +/techmap.v -map " + lib_path + family + "/arith_map.v", "(unless -no_adder)");
                } else {
                    run("techmap");
                }
                if (!noOpt) {
                    run("opt -fast" + noDFFArgs);
                }
                if (help_mode || family == "pp3") {
                    run("muxcover -mux8 -mux4", "(for pp3)");
                }
                if (!noOpt) {
                    run("opt_expr");
                    run("opt_merge");
                    run("opt_clean");
                    run("opt" + noDFFArgs);
                }
            //}
        }

        if (check_label("map_ffs")) {
            //if (!synplify) {
                if (!noOpt) {
                    run("opt_expr");
                }
                if (help_mode) {
                    run("shregmap -minlen <min> -maxlen <max>", "(for qlf_k4n8, qlf_k6n10f)");
                    run("dfflegalize -cell <supported FF types>");
                    run("techmap -map " + lib_path + family + "/cells_map.v", "(for pp3)");
                }
                if (family == "qlf_k4n8") {
                    run("shregmap -minlen 8 -maxlen 8");
                    run("dfflegalize -cell $_DFF_P_ 0 -cell $_DFF_P??_ 0 -cell $_DFF_N_ 0 -cell $_DFF_N??_ 0 -cell $_DFFSR_???_ 0");
                } else if (family == "qlf_k6n10") {
                    run("dfflegalize -cell $_DFF_P_ 0 -cell $_DFF_PP?_ 0 -cell $_DFFE_PP?P_ 0 -cell $_DFFSR_PPP_ 0 -cell $_DFFSRE_PPPP_ 0 -cell "
                        "$_DLATCHSR_PPP_ 0");
                } else if (family == "qlf_k6n10f") {
                    run("shregmap -minlen 8 -maxlen 20");
                    std::string legalizeArgs;
                    if (noffenable) {
                        legalizeArgs = " -cell $_DFF_?N?_ 0";
                    } else if (mince_num != "") {
                        legalizeArgs = " -mince " + mince_num + " -cell $_DFFE_?N?P_ 0 -cell $_DFF_?N?_ 0"; 
                    } else {
						legalizeArgs = " -cell $_DFFE_?N?P_ 0";
					}
                    if (!nosdff) {
						if (noffenable) {
							legalizeArgs += " -cell $_SDFF_?N?_ 0";
						} else if (mince_num != "") {
							legalizeArgs += " -mince " + mince_num + " -cell $_SDFFE_?N?P_ 0 -cell $_SDFF_?N?_ 0";
						} else {
							legalizeArgs += " -cell $_SDFFE_?N?P_ 0";							
						}					
                    }
                    run("dfflegalize" + legalizeArgs);
                } else if (family == "pp3") {
                    run("dfflegalize -cell $_DFFSRE_PPPP_ 0 -cell $_DLATCH_?_ x");
                    run("techmap -map " + lib_path + family + "/cells_map.v");
                }
				std::string techMapArgs = " -map +/techmap.v -map " + lib_path + family + "/ffs_map.v";
                if (help_mode || !noffmap) {
                    run("techmap " + techMapArgs, "(unless -no_ff_map)");
                }
                if (help_mode || family == "pp3") {
                    run("opt_expr -mux_undef", "(for pp3)");
                }
                if (!noOpt) {
                    run("opt_merge");
                    run("opt_clean");
                    run("opt" + noDFFArgs);
                }
            //}
        }

        if (check_label("map_luts")) {
            //if (!synplify) {
                if (help_mode || abcOpt) {
                    if (help_mode || family == "qlf_k6n10" || family == "qlf_k6n10f") {
                        if (abc9) {
                            run("read_verilog -lib -specify -icells +/quicklogic/pp3/abc9_model.v");
                            // run("techmap -map +/quicklogic/pp3/abc9_map.v");
                            // run("abc9 -maxlut 6 -dff");
                            run("abc9 -maxlut 6");
                            // run("techmap -map +/quicklogic/pp3/abc9_unmap.v");
                        } else {
                            if(custom_abc_script == ""){
                                if(de == "")
                                    run("abc -lut 6 ", "(for qlf_k6n10, qlf_k6n10f)");

                                else{
                                    if (synplify) {
                                        std::string family_path = " " + lib_path + family;
                                        run("flatten");
                                        run("techmap -map" + family_path + "/synplify_map.v");
                                        run("techmap");
                                    }
                                    run("design -save base");
                                    run("design -load base");
                                    run("tee -o abc_lut6.log abc -script +/quicklogic/abc_scripts/lut6.scr", "(for qlf_k6n10, qlf_k6n10f)");
                                    run("design -save lut6");
                                    run("write_blif lut6.blif");
                                    run("design -load base");
                                    if(de == "delay")
                                        run("tee -o abc_de.log abc -script +/quicklogic/abc_scripts/dde.scr", "(for qlf_k6n10, qlf_k6n10f)");
                                    if(de == "area")
                                        run("tee -o abc_de.log abc -script +/quicklogic/abc_scripts/ade.scr", "(for qlf_k6n10, qlf_k6n10f)");
                                    if(de == "mixed")
                                        run("tee -o abc_de.log abc -script +/quicklogic/abc_scripts/mde.scr", "(for qlf_k6n10, qlf_k6n10f)");
                                    run("design -save de");
                                    run("write_blif de.blif");
                                    
                                    if (!check_equivalence("abc_de.log")) {
                                        log("Networks are not Equivalent. Cannot use DE for this module.\n");
                                        run("design -load lut6");
                                    }
                                    else {
                                        log("Networks are Equivalent after using DE.\n");
                                        auto [lut6_nd, lut6_lev] = extract_abc_metrics("abc_lut6.log");                                    
                                        auto [de_nd, de_lev] = extract_abc_metrics("abc_de.log");
                                        
                                        if(de == "delay") {
                                            if(de_lev <= lut6_lev)
                                                run("design -load de");
                                            else
                                                run("design -load lut6");
                                        }
                                        else if (de == "area") {
                                            if(de_nd <= lut6_nd)
                                                run("design -load de");
                                            else
                                                run("design -load lut6");
                                        }
                                        else if (de == "mixed") {
                                            if(de_nd <= lut6_nd && de_lev <= lut6_lev)
                                                run("design -load de");
                                            else if(de_nd >= lut6_nd && de_lev >= lut6_lev)
                                                run("design -load lut6");
                                            else{
                                                int dmin = std::min(de_lev, lut6_lev);
                                                int dmax = std::max(de_lev, lut6_lev);
                                                double D_de = (dmax == dmin) ? 0.0 : (de_lev - dmin) / (dmax - dmin);
                                                double D_lut6 = (dmax == dmin) ? 0.0 : (lut6_lev - dmin) / (dmax - dmin);

                                                int amin = std::min(de_nd, lut6_nd);
                                                int amax = std::max(de_nd, lut6_nd);
                                                double A_de = (amax == amin) ? 0.0 :
                                                (std::log(de_nd) - std::log(amin)) /
                                                (std::log(amax) - std::log(amin));
                                                double A_lut6 = (amax == amin) ? 0.0 :
                                                (std::log(lut6_nd) - std::log(amin)) /
                                                (std::log(amax) - std::log(amin));

                                                double de_score = 0.5 * A_de + 0.5 * D_de;
                                                double lut6_score = 0.5 * A_lut6 + 0.5 * D_lut6;
                                                if (de_score <= lut6_score)
                                                    run("design -load de");
                                                else 
                                                    run("design -load lut6");
                                            }
                                        }
                                    }
                                }
                            }
                            else{
                                run("abc -script " + custom_abc_script + " ", "(for qlf_k6n10, qlf_k6n10f)");
                            }
                        }
                    }
                    if (help_mode || family == "qlf_k4n8") {
                        run("abc -lut 4 ", "(for qlf_k4n8)");
                    }
                    if (help_mode || family == "pp3") {
                        run("techmap -map " + lib_path + family + "/latches_map.v", "(for pp3)");
                        if (help_mode || abc9) {
                            run("read_verilog -lib -specify -icells " + lib_path + family + "/abc9_model.v", "(for pp3)");
                            run("techmap -map " + lib_path + family + "/abc9_map.v", "   (for pp3)");
                            run("abc9 -maxlut 4 -dff", "                             (for pp3)");
                            run("techmap -map " + lib_path + family + "/abc9_unmap.v", " (for pp3)");
                        }
                        if (help_mode || !abc9) {
                            std::string lutDefs = "" + lib_path + family + "/lutdefs.txt";
                            rewrite_filename(lutDefs);

                            std::string abcArgs = help_mode ? "<script>"
                                                            : "+read_lut," + lutDefs +
                                                                ";"
                                                                "strash;ifraig;scorr;dc2;dretime;strash;dch,-f;if;mfs2;" // Common Yosys ABC script
                                                                "sweep;eliminate;if;mfs;lutpack;"                        // Optimization script
                                                                "dress";                                                 // "dress" to preserve names

                            run("abc -script " + abcArgs, "                            (for pp3 if -no_abc9)");
                        }
                    }
                }
                run("clean");
                if (!noOpt) {
                    run("opt_lut");
                }
            //}
        }

        if (check_label("map_cells", "(for pp3, qlf_k6n10)") && (help_mode || family == "qlf_k6n10" || family == "pp3")) {
            if (!synplify) {
                std::string techMapArgs;
                techMapArgs = "-map " + lib_path + family + "/lut_map.v";
                run("techmap " + techMapArgs);
                run("clean");
            }
        }
		
		if (check_label("iomap", "(for qlf_k6n10f)") && (family == "qlf_k6n10f" || help_mode)) {
			// Runs on both front ends. ql_ioff needs the Synplify path's VCC-cell
			// constants resolved to see an unused E or R at all, which
			// build_const_drivers does, so the same promotion decisions are
			// available whichever tool synthesised the design.
			if (ioff) {
				run("ql_ioff");
				run("opt_clean");
			}
		}

        if (check_label("check")) {
            if (!synplify) {
                run("autoname");
                run("hierarchy -check");
                run("stat");
                run("check -noinit");
            }
        }

        if (check_label("iomap", "(for pp3)") && (family == "pp3" || help_mode)) {
            if (!synplify) {
                run("clkbufmap -inpad ckpad Q:P");
                run("iopadmap -bits -outpad outpad A:P -inpad inpad Q:P -tinoutpad bipad EN:Q:A:P A:top");
            }
        }

        if (check_label("finalize")) {
            if (!synplify) {
                if (help_mode || family == "pp3") {
                    run("setundef -zero -params -undriven", "(for pp3)");
                }
                if (family == "pp3" || !edif_file.empty()) {
                    run("hilomap -hicell logic_1 a -locell logic_0 a -singleton A:top", "(for pp3 or if -edif)");
                }
                if (!noOpt) {
                    run("opt_clean -purge");
                }
                run("check");
                run("blackbox =A:whitebox");
            }
        }

        if (check_label("map_synplify", "(if -synplify)")) {
            std::string family_path = " " + lib_path + family;
            if (family == "qlf_k6n10f") {
                if (synplify) {
					run("opt -fast -mux_undef -undriven -fine" + noDFFArgs);
                    run("techmap -autoproc -map" + family_path + "/synplify_map.v");
                    run("opt_lut");
					run("opt" + noDFFArgs);
                    run("opt_expr");
                    run("opt_merge");
                    run("opt_clean -purge");
                    run("opt_lut_dedup");
                    run("stat");
                    run("clean");
                }
            }
            // NOTE: this label - like the "blif" label below - is nested
            // inside check_label("map_synplify"), which is a pre-existing
            // structural bug of this pass rather than something introduced
            // here: the nesting means -run link_rel_ips:blif never reaches
            // either label. Left as-is deliberately; restructuring the labels
            // is a separate change.
            if (check_label("link_rel_ips", "(if -rel_ip_blif)")) {
                // Link pre-synthesized IP netlists carrying relative-placement
                // annotations (.attr REL_*). The IP was a blackbox stub through
                // user-logic synthesis, so nothing restructured its internals;
                // replace the stub with the annotated netlist, protect the
                // annotated cells from cleanup sweeps, and flatten so IP atoms
                // get instance-prefixed names.
                if (help_mode) {
                    run("read_blif -wideports <file>", "(for each -rel_ip_blif file)");
                    run("setattr -set keep 1 a:REL_MACRO_TYPE");
                    run("flatten");
                    run("opt_expr");
                    run("opt_lut");
                    run("opt_clean -purge");
                    run("setattr -unset keep -unset src -unset hdlname a:REL_MACRO_TYPE");
                    run("hierarchy -check");
                } else if (!rel_ip_blif_files.empty()) {
                    // (module name, the -rel_ip_blif file it came from); the
                    // file is what the user can act on, so every later
                    // diagnostic names it.
                    std::vector<std::pair<std::string, std::string>> linked_ip_modules;
                    for (const auto &ip_file : rel_ip_blif_files) {
                        std::vector<std::string> mods = rel_ip_model_names(ip_file);
                        if (mods.empty())
                            log_error("-rel_ip_blif %s: no .model line found\n", ip_file.c_str());
                        // Remove already-present box definitions the file is
                        // about to (re)define. The IP module itself (first
                        // .model) must still be its EMPTY user-synthesis stub -
                        // anything else means synthesis touched it. Later
                        // .model sections are primitive declarations, which may
                        // already exist as techlib blackbox/whitebox simulation
                        // models (with contents) or from an earlier
                        // -rel_ip_blif file; those just need the blackbox
                        // attribute to be safely replaced.
                        for (size_t imod = 0; imod < mods.size(); imod++) {
                            const std::string &mod = mods[imod];
                            RTLIL::Module *existing = active_design->module(RTLIL::escape_id(mod));
                            if (existing == nullptr)
                                continue;
                            // "Empty" must mean empty of everything a module
                            // can hold, not just of cells: a stub that kept a
                            // process, a memory or a connection has been
                            // through synthesis.
                            bool is_empty_stub = existing->cells().size() == 0 && existing->processes.empty()
                                                 && existing->memories.empty() && existing->connections().empty();
                            if (imod == 0 && (!existing->get_blackbox_attribute() || !is_empty_stub))
                                log_error("-rel_ip_blif %s: module '%s' is already defined and is "
                                          "not an empty blackbox stub - the IP must pass through "
                                          "user-logic synthesis untouched\n",
                                          ip_file.c_str(), mod.c_str());
                            if (imod > 0 && !existing->get_blackbox_attribute())
                                log_error("-rel_ip_blif %s: module '%s' is already defined and is "
                                          "not a blackbox\n",
                                          ip_file.c_str(), mod.c_str());
                            active_design->remove(existing);
                        }
                        run(stringf("read_blif -wideports %s", ip_file.c_str()));

                        // The whole relative-placement flow keys on
                        // REL_MACRO_TYPE: it selects the cells to protect from
                        // optimization, and the constraint generator reads the
                        // REL_* attributes back out of the written BLIF. An IP
                        // that carries no annotation (annotate step skipped, or
                        // it produced nothing) would link, optimize and pack
                        // like ordinary logic, and the flow would report success
                        // with the macro silently unconstrained. Refuse it.
                        RTLIL::Module *linked = active_design->module(RTLIL::escape_id(mods.front()));
                        if (linked == nullptr)
                            log_error("-rel_ip_blif %s: module '%s' is missing after read_blif\n",
                                      ip_file.c_str(), mods.front().c_str());

                        const RTLIL::IdString id_rel_type = RTLIL::escape_id("REL_MACRO_TYPE");
                        const RTLIL::IdString id_rel_x = RTLIL::escape_id("REL_X");
                        const RTLIL::IdString id_rel_y = RTLIL::escape_id("REL_Y");
                        const RTLIL::IdString id_rel_subtile = RTLIL::escape_id("REL_SUBTILE");
                        // SITE_PATH carries no REL_ prefix on purpose: REL_X/REL_Y/
                        // REL_SUBTILE are offsets relative to the macro's anchor, while a
                        // site path is the absolute location of a primitive inside its
                        // cluster (and it matches the site_path attribute of VPR's
                        // constraints XML). It is still part of the annotation set
                        // validated here.
                        const RTLIL::IdString id_site_path = RTLIL::escape_id("SITE_PATH");
                        size_t num_annotated = 0;
                        for (auto cell : linked->cells()) {
                            // A cell carrying part of the annotation is worse
                            // than one carrying none: the selectors below key on
                            // REL_MACRO_TYPE, so a cell missing exactly that
                            // attribute is neither protected from optimization
                            // nor given a REL_MACRO_NAME, while its remaining
                            // annotation attributes suggest it is constrained.
                            // Mixed annotated/unannotated cells are normal, so
                            // only cells with a partial set are an error.
                            bool has_type = cell->attributes.count(id_rel_type) != 0;
                            bool has_offsets = cell->attributes.count(id_rel_x) != 0
                                               || cell->attributes.count(id_rel_y) != 0
                                               || cell->attributes.count(id_rel_subtile) != 0
                                               || cell->attributes.count(id_site_path) != 0;
                            if (!has_type && !has_offsets)
                                continue;
                            if (!has_type || cell->attributes.count(id_rel_x) == 0
                                || cell->attributes.count(id_rel_y) == 0
                                || cell->attributes.count(id_rel_subtile) == 0) {
                                log_error("-rel_ip_blif %s: cell '%s' of module '%s' carries an incomplete "
                                          "relative-placement annotation (REL_MACRO_TYPE, REL_X, REL_Y and "
                                          "REL_SUBTILE are all required; SITE_PATH is optional). Re-author the "
                                          "IP netlist.\n",
                                          ip_file.c_str(), log_id(cell->name), mods.front().c_str());
                            }
                            num_annotated++;
                        }
                        if (num_annotated == 0)
                            log_error("-rel_ip_blif %s: module '%s' carries no relative-placement annotation "
                                      "(no cell has a REL_MACRO_TYPE attribute), so it cannot be constrained. "
                                      "Was the annotate step of the IP authoring flow skipped?\n",
                                      ip_file.c_str(), mods.front().c_str());
                        log("Relative placement: linked '%s' from %s (%zu annotated cell(s))\n",
                            mods.front().c_str(), ip_file.c_str(), num_annotated);

                        linked_ip_modules.push_back(std::make_pair(mods.front(), ip_file));
                    }

                    // Stamp a design-unique REL_MACRO_NAME on each IP instance's
                    // annotated cells, derived from the instance name (the user
                    // design is flat by this point, so instance names are
                    // unique). The library netlist deliberately carries no
                    // name; several instances of one IP share its module, so
                    // every instance after the first gets its own module copy
                    // before stamping.
                    const RTLIL::IdString id_type = RTLIL::escape_id("REL_MACRO_TYPE");
                    const RTLIL::IdString id_name = RTLIL::escape_id("REL_MACRO_NAME");
                    pool<std::string> used_inst_names;
                    for (const auto &linked_ip : linked_ip_modules) {
                        const std::string &mod_name = linked_ip.first;
                        const std::string &ip_file = linked_ip.second;
                        RTLIL::Module *ip = active_design->module(RTLIL::escape_id(mod_name));
                        if (ip == nullptr)
                            continue;
                        std::vector<RTLIL::Cell *> insts;
                        for (auto module : active_design->modules())
                            if (module != ip)
                                for (auto cell : module->cells())
                                    if (cell->type == ip->name)
                                        insts.push_back(cell);
                        if (insts.empty()) {
                            // Not a warning: an IP that is linked but never
                            // instantiated contributes no cells, so its whole
                            // macro silently disappears from the constraints.
                            log_error("-rel_ip_blif %s: module '%s' is never instantiated, so it would "
                                      "contribute no relative-placement constraints\n",
                                      ip_file.c_str(), mod_name.c_str());
                        }
                        for (size_t i = 0; i < insts.size(); i++) {
                            std::string inst_name = log_id(insts[i]->name);
                            if (!used_inst_names.insert(inst_name).second)
                                log_error("-rel_ip_blif: duplicate IP instance name '%s' - "
                                          "REL_MACRO_NAME values must be design-unique (is the "
                                          "user design flattened?)\n", inst_name.c_str());
                            RTLIL::Module *target = ip;
                            if (i > 0) {
                                RTLIL::Module *copy = ip->clone();
                                copy->name = RTLIL::escape_id(mod_name + "$" + inst_name);
                                active_design->add(copy);
                                insts[i]->type = copy->name;
                                target = copy;
                            }
                            for (auto cell : target->cells())
                                if (cell->attributes.count(id_type))
                                    cell->attributes[id_name] = RTLIL::Const(inst_name);
                        }
                    }

                    run("setattr -set keep 1 a:REL_MACRO_TYPE");
                    run("flatten");
                    // Fold the ordinary constant expressions the linked netlist
                    // carries, which the IP's standalone synthesis run would
                    // have folded before write.
                    //
                    // What protects the annotated atoms here is NOT the keep
                    // attribute: opt_expr has no keep check on cells at all (its
                    // only keep test is on wires). They are safe because
                    // opt_expr has no rewrite rule and no fold-table entry for
                    // $lut/$sop, so it cannot rewrite a LUT atom. Two opt_expr
                    // paths do reach keep-marked cells - constant-connection
                    // replacement, and the clock-polarity celltype swap for
                    // .latch-based designs - so do not assume keep is a shield
                    // in this pass. (QL IPs instantiate .subckt dffre/sdffre
                    // rather than .latch, so the swap path is not reachable for
                    // them today.)
                    run("opt_expr");
                    // opt_expr cannot fold a LUT mask at all (see above), and
                    // it also cannot see BLIF constants as constants: read_blif
                    // materialises $false/$true as wires driven by degenerate
                    // .names cells. opt_lut evaluates the LUT masks themselves
                    // and collapses such cells (a LUT reading one net on several
                    // inputs degenerates to a buffer or a constant). Without
                    // this, cross-instance reductions over constant IP outputs
                    // survive into the packed netlist, where a port with the
                    // same net on two pins breaks the post-routing atom-pin
                    // remapping. opt_lut does respect keep: a keep-marked cell
                    // is used neither as absorber nor as absorbed, so the
                    // annotated atoms are preserved.
                    run("opt_lut");
                    // Merge and purge the port-boundary alias wires flatten
                    // leaves behind; without this, write_blif emits
                    // duplicate-driver alias buffers (including degenerate
                    // self-aliases), which VPR rejects as duplicate atom names.
                    // opt_clean respects keep (its keep cache retains
                    // keep-marked wires and cells, and -purge does not override
                    // that), so the annotated atoms are not swept.
                    run("opt_clean -purge");
                    // The attributes above have done their job. keep must not
                    // survive into the written BLIF: write_blif -attr dumps the
                    // whole attribute dict, so it would ship as junk in the
                    // product netlist, and on any read-back (e.g. the DSP-V4
                    // round-trip below) it would block the very buffer folding
                    // that round-trip exists to perform. src/hdlname are
                    // dropped for the same reason - they would leak absolute
                    // build paths of the authoring machine into a shipped
                    // netlist.
                    //
                    // Do NOT add the annotation attributes (REL_MACRO_NAME,
                    // REL_MACRO_TYPE, REL_X, REL_Y, REL_SUBTILE, SITE_PATH) to
                    // this list. Unlike keep they have a downstream consumer:
                    // the written BLIF is what the constraint generator reads to
                    // build the relative_macro_list, so stripping them here
                    // yields a constraints file with no macros (or, for
                    // SITE_PATH alone, macros with no site pins) and silently
                    // turns the feature off.
                    run("setattr -unset keep -unset src -unset hdlname a:REL_MACRO_TYPE");
                    // hierarchy -check and check -noinit both run BEFORE this
                    // label, so nothing has validated the linked-in netlist. An
                    // IP BLIF whose .subckt names an undefined model would
                    // otherwise pass synthesis and fail deep inside VPR.
                    run("hierarchy -check");
                }
            }
            // Write the clock list against the same netlist the BLIF describes.
            // generate_floorplanning.py consumes --blif_file and --clocks_file as a
            // pair, so the two must agree. Written before the -synplify mapping the
            // list still held techmap's per-port alias wires: that path's cleanup
            // (opt_merge / opt_clean -purge / clean) runs in map_synplify above, so
            // the connections SigMap canonicalizes through did not exist yet and one
            // clock net was emitted once per hard-block clock sink.
            {
                RTLIL::Design *design = yosys_get_design();
                std::string cf = clocks_file;
                if (cf.empty()) {
                    cf = std::string(log_id(design->top_module()->name)) + ".clocks";
                }
                std::ofstream ofs(cf);
                for (RTLIL::Module *mod : design->selected_modules()) {
                    auto clock_wires = find_clock_wires(mod);
                    for (auto wire : clock_wires) {
                        ofs << log_id(wire->name) << "\n";
                    }
                }
            }
            if (check_label("blif", "(if -blif)")) {
                if (help_mode || !blif_file.empty()) {
                    // The default flow writes exactly what upstream wrote. Only the
                    // relative-placement flow (-rel_ip_blif) extends the write:
                    // -attr/-iattr preserve cell attributes (the REL_* annotations)
                    // on .subckt and .names/.latch atoms, and -blackbox embeds a
                    // .model section per primitive so the downstream constraint
                    // generator can derive VPR atom names from port directions.
                    bool rel_flow = !rel_ip_blif_files.empty();
                    if (!help_mode && rel_flow) {
                        // The preparation below is destructive - it removes
                        // modules and calls makeblackbox(), which drops cells,
                        // processes, memories and connections - and it is only
                        // wanted for what write_blif emits. Do it on a scratch
                        // copy, exactly like the DSP-V4 round-trip below, so the
                        // real in-memory netlist survives for the later -edif
                        // and -verilog labels (without this, -rel_ip_blif
                        // -verilog x.v writes empty stubs where the default
                        // flow writes techlib bodies).
                        run("design -push-copy");
                        // write_blif -blackbox emits a .model section for every
                        // blackbox module; drop uninstantiated ones (e.g. abc9's
                        // $__ABC9_DELAY helper) - VPR requires every blackbox
                        // model in the BLIF to match an architecture model.
                        pool<RTLIL::IdString> used_types;
                        for (auto module : active_design->modules())
                            for (auto cell : module->cells())
                                used_types.insert(cell->type);
                        std::vector<RTLIL::Module *> prune;
                        for (auto module : active_design->modules())
                            if (module->get_blackbox_attribute() && !used_types.count(module->name))
                                prune.push_back(module);
                        for (auto module : prune)
                            active_design->remove(module);
                        // Instantiated blackbox/whitebox modules that still carry
                        // behavioral contents (techlib simulation models, e.g. the
                        // dffre/QL_DSP4_* bodies some flows load) trip write_blif's
                        // unmapped-process check once -blackbox includes them,
                        // even though only their port interface is written. Reduce
                        // them to true stubs.
                        for (auto module : active_design->modules())
                            if (module->get_blackbox_attribute() && (!module->processes.empty() || !module->memories.empty()))
                                module->makeblackbox();
                    }
                    const char *blif_flags = rel_flow ? "-param -attr -iattr -blackbox" : "-param";
                    run(stringf("write_blif %s %s", blif_flags, help_mode ? "<file-name>" : blif_file.c_str()));
                    if (dspv4 && !help_mode && !blif_file.empty()) {
                        // ---------------------------------------------------------------
                        // DSP-V4 BLIF buffer cleanup (round-trip).
                        //
                        // PROBLEM: several DSP-V4 leaf outputs are wide hard-block buses
                        // whose low bits are driven straight to a top-level output port -
                        // e.g. the accumulator register QL_DSP4_ACC_DFFRE_64.Q (which ALSO
                        // feeds back into QL_DSP4_ALU_ADD.Z), or QL_DSP4_ALU_ADD.ALU_OUT.
                        // A module output can't be a bit-slice of a wider internal net, so
                        // write_blif materialises each such output bit as a 1-input
                        // `.names` identity buffer (`.names src dst\n1 1`). Every one of
                        // those buffers is packed as a standalone LUT1 in VPR -> wasted CLB
                        // resources (e.g. ~36 LUTs for a 36-bit accumulate output).
                        //
                        // WHY WE CAN'T JUST opt_clean IN MEMORY: at this point the buffer
                        // is a net *alias* (connect), and its driver is a KEPT public wire
                        // (the register/ALU output net) that has extra fanout (the ALU
                        // feedback). opt_clean/opt_expr/opt_merge/splitnets - in every
                        // combination - keep that public multi-fanout net as canonical and
                        // re-emit the port as a buffered copy. So no in-memory pass folds it
                        // (without also anonymising every net name via `rename -hide`).
                        //
                        // FIX (round-trip): write the BLIF, then read it back. On read-back
                        // the port aliases come in as identity $lut CELLS (not connects) and
                        // the internal nets get non-public names, so now `opt_expr` collapses
                        // the identity $luts to plain connections and `opt_clean -purge`
                        // merges each toward the (public) output-port name - dropping the
                        // buffer while preserving the port names. Then rewrite the BLIF.
                        //
                        // design -push/-pop wraps the round-trip in a scratch design so the
                        // real in-memory netlist (needed by any later -edif/-verilog output
                        // label) is left completely untouched.
                        // ---------------------------------------------------------------
                        run("design -push");                                    // save the real design, start a scratch one
                        run("read_blif " + blif_file);                          // reload our BLIF: aliases -> identity $lut cells
                        run("opt_expr");                                        // collapse the identity $luts to connections
                        run("opt_clean -purge");                                // merge toward the output-port names (drops buffers)
                        run(stringf("write_blif %s %s", blif_flags, blif_file.c_str())); // rewrite the buffer-free BLIF (same flags as the first write)
                        run("design -pop");                                     // restore the real design untouched
                    }
                    if (!help_mode && rel_flow) {
                        // Discard the scratch copy prepared for write_blif.
                        run("design -pop");
                    }
                }
            }
        }

        if (check_label("edif", "(if -edif)") && (help_mode || !edif_file.empty())) {
            run("splitnets -ports -format ()");
            run("quicklogic_eqn");

            run(stringf("write_ql_edif -nogndvcc -attrprop -pvector par %s %s", this->currmodule.c_str(),
                        help_mode ? "<file-name>" : edif_file.c_str()));
        }

        if (check_label("verilog", "(if -verilog)")) {
            if (help_mode || !verilog_file.empty()) {
                run("write_verilog -noattr -nohex " + (help_mode ? "<file-name>" : verilog_file));
            }
        }
    }

} SynthQuicklogicPass;

PRIVATE_NAMESPACE_END
