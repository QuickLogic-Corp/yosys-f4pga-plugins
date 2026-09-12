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

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

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
        log("        link a pre-synthesized IP netlist (extended BLIF with relative-placement\n");
        log("        .attr annotations) in place of the IP's empty (* blackbox *) stub after\n");
        log("        synthesis, then flatten. The file's one .model with contents is the IP;\n");
        log("        other .model sections must be .blackbox declarations. May be repeated.\n");
        log("        Needs a read_blif that accepts .attr on .names (Aurora's Yosys has it).\n");
        log("        Documented in the Aurora repository under\n");
        log("        docs/development/relative_macro_placement/.\n");
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
        log("        Without -synplify, ql_dspv4 infers QL_DSP4 from RTL directly, and\n");
        log("        multiplies too wide for one cell's 32x18 ports are split with\n");
        log("        mul2dsp.v and inferred piecewise.\n");
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

    // Option handling: parse_options() fills the members, finalize_options()
    // applies the defaults and checks that depend on the family or the design.

    // A value option and the member it sets. -run, -top and -rel_ip_blif are
    // handled explicitly in parse_options().
    struct ValueOption {
        const char *name;
        std::string *target;
    };
    // A switch, the member it sets and the value. -no_opt sets two members
    // and is handled explicitly in parse_options().
    struct SwitchOption {
        const char *name;
        bool *target;
        bool value;
    };

    // Split "-run <from>[:<to>]"; a bare label runs only that label.
    static void parse_run_range(const std::string &spec, std::string &run_from, std::string &run_to)
    {
        size_t pos = spec.find(':');
        if (pos == std::string::npos) {
            run_from = spec;
            run_to = spec;
        } else {
            run_from = spec.substr(0, pos);
            run_to = spec.substr(pos + 1);
        }
    }

    // Fill the option members from the command line. Returns the index of
    // the first non-option argument.
    size_t parse_options(const std::vector<std::string> &args, std::string &run_from, std::string &run_to)
    {
        const ValueOption value_options[] = {
            {"-edif", &edif_file},
            {"-family", &family},
            {"-lib_path", &lib_path},
            {"-blif", &blif_file},
            {"-verilog", &verilog_file},
            {"-clocks_file", &clocks_file},
            {"-custom_abc_script", &custom_abc_script},
            {"-mince_num", &mince_num},
            {"-de", &de},
        };
        const SwitchOption switch_options[] = {
            {"-no_dsp", &nodsp, true},
            {"-no_adder", &inferAdder, false},
            {"-no_bram", &inferBram, false},
            {"-bram_types", &bramTypes, true},
            {"-no_abc_opt", &abcOpt, false},
            {"-no_abc9", &abc9, false},
            {"-no_ff_map", &noffmap, true},
            {"-nosdff", &nosdff, true},
            {"-no_ffenable", &noffenable, true},
            {"-ioff", &ioff, true},
            {"-bramecc", &bramecc, true},
            {"-dspv2", &dspv2, true},
            {"-dspv4", &dspv4, true},
            {"-no_tdpram", &notdpram, true},
            {"-synplify", &synplify, true},
        };

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            const std::string &arg = args[argidx];
            bool has_value = argidx + 1 < args.size();

            if (arg == "-run" && has_value) {
                parse_run_range(args[++argidx], run_from, run_to);
                continue;
            }
            if (arg == "-top" && has_value) {
                top_opt = "-top " + args[++argidx];
                continue;
            }
            if (arg == "-rel_ip_blif" && has_value) {
                rel_ip_blif_files.push_back(args[++argidx]);
                continue;
            }
            if (arg == "-use_dsp_cfg_params") {
                use_dsp_cfg_params = " -use_dsp_cfg_params";
                continue;
            }
            if (arg == "-no_opt") {
                noOpt = true;
                abcOpt = false;
                continue;
            }

            bool matched = false;
            for (const auto &opt : value_options) {
                if (arg == opt.name && has_value) {
                    *opt.target = args[++argidx];
                    matched = true;
                    break;
                }
            }
            for (const auto &opt : switch_options) {
                if (!matched && arg == opt.name) {
                    *opt.target = opt.value;
                    matched = true;
                    break;
                }
            }
            if (!matched)
                break;
        }
        return argidx;
    }

    // Defaults and checks that depend on the family or on the design.
    void finalize_options(RTLIL::Design *design)
    {
        if (lib_path == "+/quicklogic/")
            lib_path = design->scratchpad_get_string("ql.lib_path", lib_path);

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
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        string run_from, run_to;
        clear_flags();
        size_t argidx = parse_options(args, run_from, run_to);
        extra_args(args, argidx, design);

        if (!design->full_selection())
            log_cmd_error("This command only operates on fully selected designs!\n");

        finalize_options(design);

        log_header(design, "Executing SYNTH_QUICKLOGIC pass.\n");
        log_push();

        run_script(design, run_from, run_to);

        log_pop();
    }

    // ---- Relative-placement IP linking (-rel_ip_blif) ----------------------
    //
    // An IP netlist is an extended BLIF whose cells carry REL_MACRO_TYPE,
    // REL_X, REL_Y, REL_SUBTILE and optionally SITE_PATH. After user-logic
    // synthesis it replaces the IP's empty (* blackbox *) stub, and each
    // instance's cells get a design-unique REL_MACRO_NAME. The written BLIF
    // keeps these attributes for the constraint generator.

    // Error out unless `have` declares the same ports as `want`: names,
    // directions, and widths when check_width is set.
    static void require_same_ports(const std::string &ip_file, RTLIL::Module *want, const char *want_desc,
                                   RTLIL::Module *have, const char *have_desc, bool check_width)
    {
        for (int side = 0; side < 2; side++) {
            RTLIL::Module *a = side == 0 ? want : have;
            RTLIL::Module *b = side == 0 ? have : want;
            const char *a_desc = side == 0 ? want_desc : have_desc;
            const char *b_desc = side == 0 ? have_desc : want_desc;
            for (auto &port : a->ports) {
                RTLIL::Wire *wa = a->wire(port);
                RTLIL::Wire *wb = b->wire(port);
                if (wb == nullptr || (!wb->port_input && !wb->port_output))
                    log_error("-rel_ip_blif %s: module '%s' has a port '%s' in %s but not in %s\n", ip_file.c_str(),
                              log_id(want->name), log_id(port), a_desc, b_desc);
                if (side == 1)
                    continue;
                if (wa->port_input != wb->port_input || wa->port_output != wb->port_output)
                    log_error("-rel_ip_blif %s: module '%s': port '%s' is an %s in %s but an %s in %s\n", ip_file.c_str(),
                              log_id(want->name), log_id(port), wa->port_input ? "input" : "output", a_desc,
                              wb->port_input ? "input" : "output", b_desc);
                if (check_width && wa->width != wb->width)
                    log_error("-rel_ip_blif %s: module '%s': port '%s' is %d bits wide in %s but %d in %s\n",
                              ip_file.c_str(), log_id(want->name), log_id(port), wa->width, a_desc, wb->width, b_desc);
            }
        }
    }

    // Describe a cell by the net it drives. read_blif leaves cells unnamed,
    // and the output net is how VPR and the constraint generator name an atom.
    static std::string rel_cell_desc(RTLIL::Cell *cell)
    {
        RTLIL::Module *tpl = cell->module->design->module(cell->type);
        for (auto &conn : cell->connections()) {
            bool is_output = cell->type.in(ID($lut), ID($sop)) ? conn.first == ID::Y
                             : tpl != nullptr && tpl->wire(conn.first) != nullptr && tpl->wire(conn.first)->port_output;
            if (is_output && !conn.second.is_fully_const())
                return stringf("the %s cell driving '%s'", log_id(cell->type), log_signal(conn.second));
        }
        return stringf("cell '%s'", log_id(cell->name));
    }

    static bool is_decimal_integer(const std::string &s)
    {
        size_t i = (!s.empty() && s[0] == '-') ? 1 : 0;
        if (i >= s.size())
            return false;
        for (; i < s.size(); i++)
            if (!isdigit(s[i]))
                return false;
        return true;
    }

    // Every annotated cell needs REL_MACRO_TYPE, REL_X, REL_Y and REL_SUBTILE
    // as quoted strings (offsets decimal); SITE_PATH is optional. An IP with
    // no annotation at all is refused: it would pack as ordinary logic.
    // Returns the number of annotated cells.
    static size_t check_rel_ip_annotation(RTLIL::Module *ip, const std::string &ip_file)
    {
        const RTLIL::IdString id_type = RTLIL::escape_id("REL_MACRO_TYPE");
        const RTLIL::IdString id_x = RTLIL::escape_id("REL_X");
        const RTLIL::IdString id_y = RTLIL::escape_id("REL_Y");
        const RTLIL::IdString id_subtile = RTLIL::escape_id("REL_SUBTILE");
        const RTLIL::IdString id_site_path = RTLIL::escape_id("SITE_PATH");
        size_t num_annotated = 0;
        for (auto cell : ip->cells()) {
            bool has_type = cell->attributes.count(id_type) != 0;
            bool has_any = has_type || cell->attributes.count(id_x) || cell->attributes.count(id_y) ||
                           cell->attributes.count(id_subtile) || cell->attributes.count(id_site_path);
            if (!has_any)
                continue;
            if (!has_type || !cell->attributes.count(id_x) || !cell->attributes.count(id_y) || !cell->attributes.count(id_subtile))
                log_error("-rel_ip_blif %s: %s in module '%s' carries an incomplete relative-placement "
                          "annotation (REL_MACRO_TYPE, REL_X, REL_Y and REL_SUBTILE are all required; SITE_PATH is "
                          "optional). Re-author the IP netlist.\n",
                          ip_file.c_str(), rel_cell_desc(cell).c_str(), log_id(ip->name));
            for (auto id : {id_type, id_x, id_y, id_subtile, id_site_path}) {
                if (!cell->attributes.count(id))
                    continue;
                const RTLIL::Const &value = cell->attributes.at(id);
                if (!(value.flags & RTLIL::CONST_FLAG_STRING))
                    log_error("-rel_ip_blif %s: %s in module '%s': attribute %s must be a quoted string in the "
                              "BLIF (an unquoted value is read as a bit vector)\n",
                              ip_file.c_str(), rel_cell_desc(cell).c_str(), log_id(ip->name), log_id(id));
                if (id != id_type && id != id_site_path && !is_decimal_integer(value.decode_string()))
                    log_error("-rel_ip_blif %s: %s in module '%s': attribute %s must be a decimal integer, "
                              "got \"%s\"\n",
                              ip_file.c_str(), rel_cell_desc(cell).c_str(), log_id(ip->name), log_id(id),
                              value.decode_string().c_str());
            }
            num_annotated++;
        }
        if (num_annotated == 0)
            log_error("-rel_ip_blif %s: module '%s' carries no relative-placement annotation (no cell has a "
                      "REL_MACRO_TYPE attribute), so it cannot be constrained. Was the annotate step of the IP "
                      "authoring flow skipped?\n",
                      ip_file.c_str(), log_id(ip->name));
        return num_annotated;
    }

    // Read one IP file and link its module in place of the stub. linked_from
    // maps the modules linked so far to their files.
    RTLIL::Module *import_rel_ip(const std::string &ip_file, dict<RTLIL::IdString, std::string> &linked_from)
    {
        // Read into a private design. The file may declare primitives the cell
        // library already defines, and the library's versions must stay: their
        // port attributes (clkbuf_sink) are what the .clocks file is built from.
        if (!std::ifstream(ip_file).good())
            log_error("-rel_ip_blif %s: cannot open the file\n", ip_file.c_str());
        RTLIL::Design *ip_design = new RTLIL::Design;
        Pass::call(ip_design, {"read_blif", "-wideports", ip_file});

        // The IP is the one .model with contents; all others must be .blackbox
        // declarations. VPR and the constraint generator apply the same rule,
        // and the order of the sections in the file means nothing.
        RTLIL::Module *ip_mod = nullptr;
        for (auto mod : ip_design->modules()) {
            if (mod->get_blackbox_attribute())
                continue;
            if (ip_mod != nullptr)
                log_error("-rel_ip_blif %s: models '%s' and '%s' both have contents; the IP netlist must be flat, "
                          "with a single .model containing primitives and every other .model a .blackbox "
                          "declaration\n",
                          ip_file.c_str(), log_id(ip_mod->name), log_id(mod->name));
            ip_mod = mod;
        }
        if (ip_mod == nullptr)
            log_error("-rel_ip_blif %s: no .model with contents found\n", ip_file.c_str());

        if (linked_from.count(ip_mod->name))
            log_error("-rel_ip_blif %s: module '%s' was already linked from %s\n", ip_file.c_str(),
                      log_id(ip_mod->name), linked_from.at(ip_mod->name).c_str());
        linked_from[ip_mod->name] = ip_file;

        // The stub must still be the empty blackbox that synthesis saw.
        RTLIL::Module *stub = active_design->module(ip_mod->name);
        if (stub == nullptr)
            log_error("-rel_ip_blif %s: module '%s' is not part of the design; read a (* blackbox *) stub of the IP "
                      "together with the user RTL\n",
                      ip_file.c_str(), log_id(ip_mod->name));
        bool is_empty_stub = stub->cells().size() == 0 && stub->processes.empty() && stub->memories.empty() &&
                             stub->connections().empty();
        if (!stub->get_blackbox_attribute() || !is_empty_stub)
            log_error("-rel_ip_blif %s: module '%s' is already defined and is not an empty blackbox stub - the IP "
                      "must pass through user-logic synthesis untouched\n",
                      ip_file.c_str(), log_id(ip_mod->name));
        // Ports must match exactly; flatten would only warn on a width
        // mismatch and connect the wrong bits.
        require_same_ports(ip_file, ip_mod, "the IP netlist", stub, "the stub", true);

        // Primitive declarations: the cell library is the authority. Keep its
        // definition, after checking the file declares the same ports.
        for (auto mod : ip_design->modules()) {
            if (mod == ip_mod)
                continue;
            RTLIL::Module *existing = active_design->module(mod->name);
            if (existing == nullptr)
                log_error("-rel_ip_blif %s: the IP declares primitive '%s', which the cell library does not define; "
                          "was the IP authored for another device or DSP option (-dspv2, -dspv4)?\n",
                          ip_file.c_str(), log_id(mod->name));
            if (!existing->get_blackbox_attribute())
                log_error("-rel_ip_blif %s: '%s' is declared as a primitive by the IP netlist but is a module with "
                          "contents in the design\n",
                          ip_file.c_str(), log_id(mod->name));
            require_same_ports(ip_file, mod, "the IP netlist's declaration", existing, "the cell library", false);
        }

        active_design->remove(stub);
        RTLIL::Module *linked = ip_mod->clone();
        active_design->add(linked);
        delete ip_design;

        // Every primitive the IP instantiates must exist in the library with
        // the pins the IP uses. The usual cause of a miss is an IP authored for
        // another device or DSP option.
        for (auto cell : linked->cells()) {
            if (cell->type.begins_with("$"))
                continue;
            RTLIL::Module *tpl = active_design->module(cell->type);
            if (tpl == nullptr)
                log_error("-rel_ip_blif %s: the IP instantiates primitive '%s', which the cell library does not "
                          "define; was the IP authored for another device or DSP option (-dspv2, -dspv4)?\n",
                          ip_file.c_str(), log_id(cell->type));
            for (auto &conn : cell->connections()) {
                RTLIL::Wire *port = tpl->wire(conn.first);
                if (port == nullptr || port->port_id == 0)
                    log_error("-rel_ip_blif %s: %s connects pin '%s', which primitive '%s' does not have\n",
                              ip_file.c_str(), rel_cell_desc(cell).c_str(), log_id(conn.first), log_id(cell->type));
                if (port->width != GetSize(conn.second))
                    log_error("-rel_ip_blif %s: %s connects %d bit(s) to pin '%s' of primitive '%s', which is %d "
                              "bit(s) wide\n",
                              ip_file.c_str(), rel_cell_desc(cell).c_str(), GetSize(conn.second), log_id(conn.first),
                              log_id(cell->type), port->width);
            }
        }

        size_t num_annotated = check_rel_ip_annotation(linked, ip_file);
        log("Relative placement: linked '%s' from %s (%zu annotated cell(s))\n", log_id(linked->name), ip_file.c_str(),
            num_annotated);
        return linked;
    }

    // Stamp REL_MACRO_NAME = instance name on the annotated cells of every
    // instance of `ip`. Instances after the first get their own copy of the
    // module, since all instances share it otherwise.
    void stamp_rel_macro_names(RTLIL::Module *ip, const std::string &ip_file)
    {
        const RTLIL::IdString id_type = RTLIL::escape_id("REL_MACRO_TYPE");
        const RTLIL::IdString id_name = RTLIL::escape_id("REL_MACRO_NAME");

        // Instance names are unique only within one module. The design was
        // flattened in `prepare`, so every instance must be in the top module.
        RTLIL::Module *top = active_design->top_module();
        if (top == nullptr)
            log_error("-rel_ip_blif %s: the design has no top module; run the flow from the `begin` label\n",
                      ip_file.c_str());
        std::vector<RTLIL::Cell *> insts;
        for (auto module : active_design->modules())
            for (auto cell : module->cells())
                if (cell->type == ip->name) {
                    if (module != top)
                        log_error("-rel_ip_blif %s: instance '%s' of '%s' sits in module '%s', not in the top "
                                  "module; the design must be flat when the IP is linked\n",
                                  ip_file.c_str(), log_id(cell->name), log_id(ip->name), log_id(module->name));
                    insts.push_back(cell);
                }
        // An IP that is never instantiated would silently drop out of the
        // constraints.
        if (insts.empty())
            log_error("-rel_ip_blif %s: module '%s' is never instantiated, so it would contribute no "
                      "relative-placement constraints\n",
                      ip_file.c_str(), log_id(ip->name));

        for (size_t i = 0; i < insts.size(); i++) {
            std::string inst_name = log_id(insts[i]->name);
            RTLIL::Module *target = ip;
            if (i > 0) {
                target = ip->clone();
                target->name = RTLIL::escape_id(std::string(log_id(ip->name)) + "$" + inst_name);
                active_design->add(target);
                insts[i]->type = target->name;
            }
            for (auto cell : target->cells())
                if (cell->attributes.count(id_type))
                    cell->attributes[id_name] = RTLIL::Const(inst_name);
        }
    }

    // Import every IP file, stamp macro names, then flatten so the IP cells
    // get instance-prefixed names. The annotated cells are marked keep while
    // the cleanup passes run.
    void link_rel_ips()
    {
        if (help_mode) {
            run("read_blif -wideports <file>", "(for each -rel_ip_blif file)");
            run("setattr -set keep 1 a:REL_MACRO_TYPE");
            run("flatten");
            run("opt_expr");
            run("opt_lut", "(unless -no_opt)");
            run("setattr -unset keep a:REL_MACRO_TYPE");
            run("opt_clean -purge");
            run("hierarchy -check");
            run("check");
            run("stat");
            return;
        }
        if (rel_ip_blif_files.empty())
            return;

        pool<std::string> seen_files;
        dict<RTLIL::IdString, std::string> linked_from;
        std::vector<std::pair<RTLIL::Module *, std::string>> linked;
        for (const auto &ip_file : rel_ip_blif_files) {
            if (!seen_files.insert(ip_file).second)
                log_error("-rel_ip_blif %s: the same file is given twice\n", ip_file.c_str());
            linked.push_back(std::make_pair(import_rel_ip(ip_file, linked_from), ip_file));
        }
        for (const auto &it : linked)
            stamp_rel_macro_names(it.first, it.second);

        // keep stops opt_lut from merging an annotated LUT into a neighbour.
        run("setattr -set keep 1 a:REL_MACRO_TYPE");
        run("flatten");
        // Fold the constants the linked netlist still carries. opt_expr never
        // rewrites $lut cells, so the annotated LUTs are safe.
        run("opt_expr");
        // Fold LUTs whose inputs became constant or identical through the
        // link; VPR rejects the same net on two pins. Skipped with -no_opt
        // because it also merges user LUTs.
        if (!noOpt)
            run("opt_lut");
        // Unset keep before the cleanup so dead annotated cells go, as VPR's
        // dangling-block sweep would remove them anyway. The REL_* stay.
        run("setattr -unset keep a:REL_MACRO_TYPE");
        // Also drops the alias wires flatten leaves at the old IP ports.
        run("opt_clean -purge");
        // Validate the linked netlist against the cell library and report it.
        run("hierarchy -check");
        run("check");
        run("stat");
    }

    // Trim the scratch copy that write_blif -blackbox writes.
    void prepare_rel_blif_scratch()
    {
        // VPR needs every .model to match an architecture model: drop the
        // blackboxes nothing instantiates (e.g. abc9's $__ABC9_DELAY).
        pool<RTLIL::IdString> used_types;
        for (auto module : active_design->modules())
            for (auto cell : module->cells())
                used_types.insert(cell->type);
        for (auto module : active_design->modules().to_vector())
            if (module->get_blackbox_attribute() && !used_types.count(module->name))
                active_design->remove(module);

        // -attr writes every cell attribute. Keep only the annotation set: the
        // default flow writes no attributes, and src/hdlname would leak paths.
        pool<RTLIL::IdString> rel_attrs;
        for (const char *name : {"REL_MACRO_NAME", "REL_MACRO_TYPE", "REL_X", "REL_Y", "REL_SUBTILE", "SITE_PATH"})
            rel_attrs.insert(RTLIL::escape_id(name));
        for (auto module : active_design->modules()) {
            // write_blif refuses processes and memories even in blackbox
            // modules; reduce simulation models to port-only stubs.
            if (module->get_blackbox_attribute() && (!module->processes.empty() || !module->memories.empty()))
                module->makeblackbox();
            for (auto cell : module->cells()) {
                std::vector<RTLIL::IdString> drop;
                for (auto &attr : cell->attributes)
                    if (!rel_attrs.count(attr.first))
                        drop.push_back(attr.first);
                for (auto &id : drop)
                    cell->attributes.erase(id);
            }
        }
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

        if (check_label("map_dsp", "(skip if -no_dsp)")) {
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

                            // Wide multiplies. ql_dspv4 above only takes what
                            // fits one cell's 32x18 ports, so a 48x32 was still
                            // a $mul afterwards and went to fabric whole -- 2952
                            // LUTs where four DSPs would do. mul2dsp.v splits it
                            // into 32x18 pieces plus $shl/$add glue, the same way
                            // the V2 arm below and the V1 arm above use it.
                            //
                            // No dsp_map.v equivalent is needed. mul2dsp emits
                            // DSP_NAME cells with a $mul interface -- same five
                            // parameters, same A/B/Y ports -- so chtype hands the
                            // pieces straight back to the pass that already knows
                            // how to emit QL_DSP4, control word and all. That is
                            // also what keeps V4 off the V1/V2 device collateral
                            // a DSP-V4 device does not ship (see above).
                            //
                            // ql_dspv4 runs FIRST because mul2dsp knows nothing
                            // about MULT_ADD_C / MULT_ACC or absorbed registers
                            // and would chop a fusable multiply apart. Same order
                            // as the V2 arm's ql_dsp_macc -> mul2dsp.
                            //
                            // MINWIDTH is 2, not the V2 arm's 10: mul2dsp's last
                            // partial is A_WIDTH - 31*floor((A_WIDTH-2)/31), whose
                            // minimum is exactly 2 (17 for B), so 2 never rejects
                            // a partial, and 10 would push one to fabric where it
                            // would still need its adder. SIGNEDONLY gives an
                            // unsigned operand the spare bit the signed
                            // Baugh-Wooley multiplier needs, which is the same
                            // rule ql_dspv4's own capacity check applies.
                            run("techmap -map +/mul2dsp.v "
                                "-D DSP_A_MAXWIDTH=32 -D DSP_B_MAXWIDTH=18 "
                                "-D DSP_A_MINWIDTH=2 -D DSP_B_MINWIDTH=2 "
                                "-D DSP_SIGNEDONLY "
                                "-D DSP_NAME=$__QL_DSP4_MUL");
                            // Before the opt below, so no unknown cell type is
                            // ever in the design.
                            run("chtype -set $mul t:$__QL_DSP4_MUL");
                            // Trim the glue mul2dsp just emitted without
                            // disturbing the rest of the design, as the V1 arm
                            // does.
                            run("select a:mul2dsp");
                            run("setattr -unset mul2dsp");
                            if (!noOpt) {
                                run("opt_expr -fine");
                                run("wreduce");
                            }
                            run("select -clear");
                            run("ql_dspv4");
                            // Restore the multiplies mul2dsp declined as too
                            // narrow. Last, so they stay a distinct type across
                            // the run above and MINWIDTH keeps meaning something
                            // -- ql_dspv4 has no lower width bound of its own and
                            // would otherwise re-claim them.
                            run("chtype -set $mul t:$__soft_mul");
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
        }

        if (check_label("link_rel_ips", "(if -rel_ip_blif)"))
            link_rel_ips();

        // Write the clock list against the same netlist the BLIF describes.
        // generate_floorplanning.py consumes --blif_file and --clocks_file as a
        // pair, so the two must agree. Written before the -synplify mapping the
        // list still held techmap's per-port alias wires: that path's cleanup
        // (opt_merge / opt_clean -purge / clean) runs in map_synplify above, so
        // the connections SigMap canonicalizes through did not exist yet and one
        // clock net was emitted once per hard-block clock sink.
        // Not run in help mode: plain C++, no design.
        if (check_label("clocks", "(writes the -clocks_file)") && !help_mode) {
            std::string cf = clocks_file;
            if (cf.empty()) {
                if (active_design->top_module() == nullptr)
                    log_error("no -clocks_file given and no top module to name the .clocks file after\n");
                cf = std::string(log_id(active_design->top_module()->name)) + ".clocks";
            }
            std::ofstream ofs(cf);
            for (RTLIL::Module *mod : active_design->selected_modules()) {
                auto clock_wires = find_clock_wires(mod);
                for (auto wire : clock_wires) {
                    ofs << log_id(wire->name) << "\n";
                }
            }
        }
        if (check_label("blif", "(if -blif)")) {
            if (help_mode || !blif_file.empty()) {
                // Only the relative-placement flow adds flags: -attr/-iattr keep
                // the REL_* annotations, -blackbox writes a .model per primitive
                // (the constraint generator derives VPR atom names from them).
                bool rel_flow = !rel_ip_blif_files.empty();
                const char *blif_flags = rel_flow ? "-param -attr -iattr -blackbox" : "-param";
                if (!help_mode && rel_flow) {
                    // Work on a scratch copy: the in-memory netlist is still
                    // needed for -edif and -verilog.
                    run("design -push-copy");
                    prepare_rel_blif_scratch();
                }
                run(stringf("write_blif %s %s", blif_flags, help_mode ? "<file-name>" : blif_file.c_str()),
                    "(-attr -iattr -blackbox with -rel_ip_blif)");
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
                if (!help_mode && rel_flow)
                    run("design -pop"); // discard the scratch copy
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
