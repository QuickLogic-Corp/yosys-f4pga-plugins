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
 */

#include "kernel/log.h"
#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/sigtools.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

#define MODE_BITS_BASE_SIZE 80
#define MODE_BITS_EXTENSION_SIZE 13

// ============================================================================

struct QlDspSimdPass : public Pass {

    QlDspSimdPass() : Pass("ql_dsp_simd", "Infers QuickLogic k6n10f DSP pairs that can operate in SIMD mode") {}

    void help() override
    {
        log("\n");
        log("    ql_dsp_simd [options] [selection]\n");
        log("\n");
        log("    This pass identifies k6n10f DSP cells with identical configuration\n");
        log("    and packs pairs of them together into other DSP cells that can\n");
        log("    perform SIMD operation.\n");
        log("\n");
        log("    -dspv2\n");
        log("        Pack pairs of dspv2_16x9x32_cfg_ports cells into a single\n");
        log("        dspv2_32x18x64_cfg_ports cell with FRAC_MODE=1 (fractured 2x 16x9).\n");
        log("        Source cells must agree on every config port and config parameter\n");
        log("        except COEFF_0 (which is concatenated low|high into the target).\n");
    }

    bool replace_existing_pass() const override
    {
        return true;
    }

    // ..........................................

    /// Describes DSP config unique to a whole DSP cell
    struct DspConfig {

        // Port connections
        dict<RTLIL::IdString, RTLIL::SigSpec> connections;

        // Whether DSPs pass configuration bits through ports of parameters
        bool use_cfg_params;

        // Parameter values (used by -dspv2 mode where most controls are
        // cfg-parameters on the wrapper). Two halves can only pack if every
        // entry here matches between them.
        dict<RTLIL::IdString, RTLIL::Const> params;

        // TODO: Possibly include parameters here. For now we have just
        // connections.

        DspConfig() = default;

        DspConfig(const DspConfig &ref) = default;
        DspConfig(DspConfig &&ref) = default;

        #if defined YS_HASHING_VERSION && YS_HASHING_VERSION == 1
                Hasher hash_into(Hasher h) const {
                h.eat(connections);
                h.eat(params);
                return h;
                }
        #else
            #error "This version of Yosys uses an unsupported hashing interface"
        #endif

        bool operator==(const DspConfig &ref) const { return connections == ref.connections && use_cfg_params == ref.use_cfg_params && params == ref.params; }
    };

    // ..........................................

    // DSP control and config ports to consider and how to map them to ports
    // of the target DSP cell
    const std::vector<std::pair<std::string, std::string>> m_DspCfgPorts = {std::make_pair("clock_i", "clk"),
                                                                            std::make_pair("reset_i", "reset"),

                                                                            std::make_pair("feedback_i", "feedback"),
                                                                            std::make_pair("load_acc_i", "load_acc"),
                                                                            std::make_pair("unsigned_a_i", "unsigned_a"),
                                                                            std::make_pair("unsigned_b_i", "unsigned_b"),

                                                                            std::make_pair("subtract_i", "subtract")};
    // For QL_DSP2 expand with configuration ports
    const std::vector<std::pair<std::string, std::string>> m_DspCfgPorts_expand = {
      std::make_pair("output_select_i", "output_select"), std::make_pair("saturate_enable_i", "saturate_enable"),
      std::make_pair("shift_right_i", "shift_right"), std::make_pair("round_i", "round"), std::make_pair("register_inputs_i", "register_inputs")};

    // For QL_DSP3 use parameters instead
    const std::vector<std::string> m_DspParams2Mode = {"OUTPUT_SELECT", "SATURATE_ENABLE", "SHIFT_RIGHT", "ROUND", "REGISTER_INPUTS"};

    // DSP data ports and how to map them to ports of the target DSP cell
    const std::vector<std::pair<std::string, std::string>> m_DspDataPorts = {
      std::make_pair("a_i", "a"), std::make_pair("b_i", "b"),         std::make_pair("acc_fir_i", "acc_fir"),
      std::make_pair("z_o", "z"), std::make_pair("dly_b_o", "dly_b"),
    };

    // DSP parameters
    const std::vector<std::string> m_DspParams = {"COEFF_3", "COEFF_2", "COEFF_1", "COEFF_0"};

    // Source DSP cell type (SISD)
    const std::string m_SisdDspType = "dsp_t1_10x9x32";
    // Suffix for DSP cell with configuration parameters
    const std::string m_SisdDspType_cfg_params_suffix = "_cfg_params";

    // Target DSP cell types for the SIMD mode
    const std::string m_SimdDspType_cfg_ports = "QL_DSP2";
    const std::string m_SimdDspType_cfg_params = "QL_DSP3";

    // ---- DSPv2 SIMD configuration ----
    // v2 source / target cell types.
    const std::string m_Dspv2SisdType = "dspv2_16x9x32_cfg_ports";
    const std::string m_Dspv2SimdType = "dspv2_32x18x64_cfg_ports";

    // v2 control ports that must agree between two halves to be packable.
    // Same name on source and target wrapper.
    const std::vector<std::pair<std::string, std::string>> m_Dspv2CfgPorts = {
      std::make_pair("clock_i", "clock_i"),       std::make_pair("reset_i", "reset_i"),
      std::make_pair("acc_reset_i", "acc_reset_i"), std::make_pair("feedback_i", "feedback_i"),
      std::make_pair("load_acc_i", "load_acc_i"), std::make_pair("output_select_i", "output_select_i"),
    };

    // v2 data ports. The target widths are 2x the source widths; halves are
    // concatenated low|high (dsp_a is the low half, dsp_b the high half).
    const std::vector<std::pair<std::string, std::string>> m_Dspv2DataPorts = {
      std::make_pair("a_i", "a_i"),         std::make_pair("b_i", "b_i"),         std::make_pair("c_i", "c_i"),
      std::make_pair("z_o", "z_o"),         std::make_pair("a_cin_i", "a_cin_i"), std::make_pair("b_cin_i", "b_cin_i"),
      std::make_pair("z_cin_i", "z_cin_i"), std::make_pair("a_cout_o", "a_cout_o"), std::make_pair("b_cout_o", "b_cout_o"),
      std::make_pair("z_cout_o", "z_cout_o"),
    };

    // v2 cfg-parameters that must match between the two halves. FRAC_MODE
    // and COEFF_0 are excluded: FRAC_MODE is forced to 1 on the target;
    // COEFF_0 is concatenated low|high.
    const std::vector<std::string> m_Dspv2CfgParams = {
      "ACC_FIR",   "ROUND",   "ZC_SHIFT", "ZREG_SHIFT", "SHIFT_REG", "SATURATE", "SUBTRACT", "PRE_ADD",
      "A_SEL",     "A_REG",   "A1_REG",   "A2_REG",     "B_SEL",     "B_REG",    "B1_REG",   "B2_REG",
      "C_REG",     "BC_REG",  "M_REG",    "ZCIN_REG",   "ACOUT_SEL", "BCOUT_SEL",
    };

    // Run-time mode flag (set from -dspv2 command-line argument).
    bool m_dspv2 = false;

    /// Temporary SigBit to SigBit helper map.
    SigMap m_SigMap;

    // ..........................................

    void execute(std::vector<std::string> a_Args, RTLIL::Design *a_Design) override
    {
        log_header(a_Design, "Executing QL_DSP_SIMD pass.\n");

        // Parse args
        m_dspv2 = false;
        size_t argidx;
        for (argidx = 1; argidx < a_Args.size(); argidx++) {
            if (a_Args[argidx] == "-dspv2") {
                m_dspv2 = true;
                continue;
            }
            break;
        }
        extra_args(a_Args, argidx, a_Design);

        if (m_dspv2) {
            executeDspv2(a_Design);
            return;
        }

        // Process modules
        for (auto module : a_Design->selected_modules()) {

            // Setup the SigMap
            m_SigMap.clear();
            m_SigMap.set(module);

            // Assemble DSP cell groups
            dict<DspConfig, std::vector<RTLIL::Cell *>> groups;
            for (auto cell : module->selected_cells()) {

                // Check if this is a DSP cell we are looking for (type starts with m_SisdDspType)
                if (strncmp(cell->type.c_str(), RTLIL::escape_id(m_SisdDspType).c_str(), RTLIL::escape_id(m_SisdDspType).size()) != 0) {
                    continue;
                }

                // Skip if it has the (* keep *) attribute set
                if (cell->has_keep_attr()) {
                    continue;
                }

                // Add to a group
                const auto key = getDspConfig(cell);
                groups[key].push_back(cell);
            }

            std::vector<const RTLIL::Cell *> cellsToRemove;

            // Map cell pairs to the target DSP SIMD cell
            for (const auto &it : groups) {
                const auto &group = it.second;
                const auto &config = it.first;

                bool use_cfg_params = config.use_cfg_params;
                // Ensure an even number
                size_t count = group.size();
                if (count & 1)
                    count--;

                // Map SIMD pairs
                for (size_t i = 0; i < count; i += 2) {
                    const RTLIL::Cell *dsp_a = group[i];
                    const RTLIL::Cell *dsp_b = group[i + 1];

                    std::string name = stringf("simd%ld", i / 2);
                    std::string SimdDspType;

                    if (use_cfg_params)
                        SimdDspType = m_SimdDspType_cfg_params;
                    else
                        SimdDspType = m_SimdDspType_cfg_ports;

                    log(" SIMD: %s (%s) + %s (%s) => %s (%s)\n", RTLIL::unescape_id(dsp_a->name).c_str(), RTLIL::unescape_id(dsp_a->type).c_str(),
                        RTLIL::unescape_id(dsp_b->name).c_str(), RTLIL::unescape_id(dsp_b->type).c_str(), RTLIL::unescape_id(name).c_str(),
                        SimdDspType.c_str());

                    // Create the new cell
                    RTLIL::Cell *simd = module->addCell(RTLIL::escape_id(name), RTLIL::escape_id(SimdDspType));

                    // Check if the target cell is known (important to know
                    // its port widths)
                    if (!simd->known()) {
                        log_error(" The target cell type '%s' is not known!", SimdDspType.c_str());
                    }

                    std::vector<std::pair<std::string, std::string>> DspCfgPorts = m_DspCfgPorts;
                    if (!use_cfg_params)
                        DspCfgPorts.insert(DspCfgPorts.end(), m_DspCfgPorts_expand.begin(), m_DspCfgPorts_expand.end());

                    // Connect common ports
                    for (const auto &it : DspCfgPorts) {
                        auto sport = RTLIL::escape_id(it.first);
                        auto dport = RTLIL::escape_id(it.second);

                        simd->setPort(dport, config.connections.at(sport));
                    }

                    // Connect data ports
                    for (const auto &it : m_DspDataPorts) {
                        auto sport = RTLIL::escape_id(it.first);
                        auto dport = RTLIL::escape_id(it.second);

                        size_t width;
                        bool isOutput;

                        std::tie(width, isOutput) = getPortInfo(simd, dport);

                        auto getConnection = [&](const RTLIL::Cell *cell) {
                            RTLIL::SigSpec sigspec;
                            if (cell->hasPort(sport)) {
                                const auto &sig = cell->getPort(sport);
                                sigspec.append(sig);
                            }
                            if (sigspec.bits().size() < width / 2) {
                                if (isOutput) {
                                    for (size_t i = 0; i < width / 2 - sigspec.bits().size(); ++i) {
                                        sigspec.append(RTLIL::SigSpec());
                                    }
                                } else {
                                    sigspec.append(RTLIL::SigSpec(RTLIL::Sx, width / 2 - sigspec.bits().size()));
                                }
                            }
                            return sigspec;
                        };

                        RTLIL::SigSpec sigspec;
                        sigspec.append(getConnection(dsp_a));
                        sigspec.append(getConnection(dsp_b));
                        simd->setPort(dport, sigspec);
                    }

                    // Concatenate FIR coefficient parameters into the single
                    // MODE_BITS parameter
                    std::vector<RTLIL::State> mode_bits;
                    for (const auto &it : m_DspParams) {
                        auto val_a = dsp_a->getParam(RTLIL::escape_id(it));
                        auto val_b = dsp_b->getParam(RTLIL::escape_id(it));

                        mode_bits.insert(mode_bits.end(), val_a.begin(), val_a.end());
                        mode_bits.insert(mode_bits.end(), val_b.begin(), val_b.end());
                    }
                    long unsigned int mode_bits_size = MODE_BITS_BASE_SIZE;
                    if (use_cfg_params) {
                        // Add additional config parameters if necessary
                        mode_bits.push_back(RTLIL::S1); // MODE_BITS[80] == F_MODE : Enable fractured mode
                        for (const auto &it : m_DspParams2Mode) {
                            log_assert(dsp_a->getParam(RTLIL::escape_id(it)) == dsp_b->getParam(RTLIL::escape_id(it)));
                            auto param = dsp_a->getParam(RTLIL::escape_id(it));
                            if (param.size() > 1) {
                                mode_bits.insert(mode_bits.end(), param.bits().begin(), param.bits().end());
                            } else {
                                mode_bits.push_back(param.bits()[0]);
                            }
                        }
                        mode_bits_size += MODE_BITS_EXTENSION_SIZE;
                    } else {
                        // Enable the fractured mode by connecting the control
                        // port.
                        simd->setPort(RTLIL::escape_id("f_mode"), RTLIL::S1);
                    }
                    simd->setParam(RTLIL::escape_id("MODE_BITS"), RTLIL::Const(mode_bits));
                    log_assert(mode_bits.size() == mode_bits_size);

                    // Handle the "is_inferred" attribute. If one of the fragments
                    // is not inferred mark the whole DSP as not inferred
                    bool is_inferred_a =
                      dsp_a->has_attribute(RTLIL::escape_id("is_inferred")) ? dsp_a->get_bool_attribute(RTLIL::escape_id("is_inferred")) : false;
                    bool is_inferred_b =
                      dsp_b->has_attribute(RTLIL::escape_id("is_inferred")) ? dsp_b->get_bool_attribute(RTLIL::escape_id("is_inferred")) : false;

                    simd->set_bool_attribute(RTLIL::escape_id("is_inferred"), is_inferred_a && is_inferred_b);

                    // Mark DSP parts for removal
                    cellsToRemove.push_back(dsp_a);
                    cellsToRemove.push_back(dsp_b);
                }
            }

            // Remove old cells
            for (const auto &cell : cellsToRemove) {
                module->remove(const_cast<RTLIL::Cell *>(cell));
            }
        }

        // Clear
        m_SigMap.clear();
    }

    // ..........................................

    /// Looks up port width and direction in the cell definition and returns it.
    /// Returns (0, false) if it cannot be determined.
    std::pair<size_t, bool> getPortInfo(RTLIL::Cell *a_Cell, RTLIL::IdString a_Port)
    {
        if (!a_Cell->known()) {
            return std::make_pair(0, false);
        }

        // Get the module defining the cell (the previous condition ensures
        // that the pointers are valid)
        RTLIL::Module *mod = a_Cell->module->design->module(a_Cell->type);
        if (mod == nullptr) {
            return std::make_pair(0, false);
        }

        // Get the wire representing the port
        RTLIL::Wire *wire = mod->wire(a_Port);
        if (wire == nullptr) {
            return std::make_pair(0, false);
        }

        return std::make_pair(wire->width, wire->port_output);
    }

    /// Given a DSP cell populates and returns a DspConfig struct for it.
    DspConfig getDspConfig(RTLIL::Cell *a_Cell)
    {
        DspConfig config;

        string cell_type = a_Cell->type.str();
        string suffix = m_SisdDspType_cfg_params_suffix;

        bool use_cfg_params = cell_type.size() >= suffix.size() && 0 == cell_type.compare(cell_type.size() - suffix.size(), suffix.size(), suffix);

        std::vector<std::pair<std::string, std::string>> DspCfgPorts = m_DspCfgPorts;
        if (!use_cfg_params)
            DspCfgPorts.insert(DspCfgPorts.end(), m_DspCfgPorts_expand.begin(), m_DspCfgPorts_expand.end());

        config.use_cfg_params = use_cfg_params;

        for (const auto &it : DspCfgPorts) {
            auto port = RTLIL::escape_id(it.first);

            // Port unconnected
            if (!a_Cell->hasPort(port)) {
                config.connections[port] = RTLIL::SigSpec(RTLIL::Sx);
                continue;
            }

            // Get the port connection and map it to unique SigBits
            const auto &orgSigSpec = a_Cell->getPort(port);
            const auto &orgSigBits = orgSigSpec.bits();

            RTLIL::SigSpec newSigSpec;
            for (size_t i = 0; i < orgSigBits.size(); ++i) {
                auto newSigBit = m_SigMap(orgSigBits[i]);
                newSigSpec.append(newSigBit);
            }

            // Store
            config.connections[port] = newSigSpec;
        }

        return config;
    }

    // ..........................................
    // -------- DSPv2 SIMD path ---------------------------------------------
    //
    // Pairs of dspv2_16x9x32_cfg_ports cells with identical control ports
    // and identical cfg-parameters (excluding COEFF_0 / FRAC_MODE) are packed
    // into a single dspv2_32x18x64_cfg_ports cell with FRAC_MODE forced to 1.
    // Data ports are concatenated low|high (dsp_a is the low half).

    /// Build a v2 DspConfig: control-port connections + cfg-parameters that
    /// must agree between two halves to be packable.
    DspConfig getDspv2Config(RTLIL::Cell *a_Cell)
    {
        DspConfig config;
        config.use_cfg_params = false;

        for (const auto &it : m_Dspv2CfgPorts) {
            auto port = RTLIL::escape_id(it.first);

            if (!a_Cell->hasPort(port)) {
                config.connections[port] = RTLIL::SigSpec(RTLIL::Sx);
                continue;
            }

            const auto &orgSigSpec = a_Cell->getPort(port);
            const auto &orgSigBits = orgSigSpec.bits();

            RTLIL::SigSpec newSigSpec;
            for (size_t i = 0; i < orgSigBits.size(); ++i) {
                newSigSpec.append(m_SigMap(orgSigBits[i]));
            }
            config.connections[port] = newSigSpec;
        }

        for (const auto &name : m_Dspv2CfgParams) {
            auto pname = RTLIL::escape_id(name);
            if (a_Cell->hasParam(pname)) {
                config.params[pname] = a_Cell->getParam(pname);
            }
        }

        return config;
    }

    /// Return true if the v2 SISD cell participates in an active cascade
    /// chain and therefore must NOT be SIMD-packed. A cascade is "active"
    /// when:
    ///   - any bit of a_cin_i / b_cin_i / z_cin_i is driven by something
    ///     other than constant 0 / x (after sigmap-canonicalisation), OR
    ///   - any bit of a_cout_o / b_cout_o / z_cout_o has at least one
    ///     consumer in the module (per the bit_users map built by the
    ///     caller).
    /// Packing a cascading cell would silently re-route the chain through
    /// the wider 32x18 wrapper and break the user's connectivity.
    bool isDspv2CascadeActive(RTLIL::Cell *a_Cell, const dict<RTLIL::SigBit, int> &bit_users)
    {
        for (const char *port_name : {"a_cin_i", "b_cin_i", "z_cin_i"}) {
            auto pid = RTLIL::escape_id(port_name);
            if (!a_Cell->hasPort(pid))
                continue;
            RTLIL::SigSpec mapped = m_SigMap(a_Cell->getPort(pid));
            std::vector<RTLIL::SigBit> bits = mapped.bits();
            for (auto bit : bits) {
                if (bit != RTLIL::State::S0 && bit != RTLIL::State::Sx)
                    return true;
            }
        }

        for (const char *port_name : {"a_cout_o", "b_cout_o", "z_cout_o"}) {
            auto pid = RTLIL::escape_id(port_name);
            if (!a_Cell->hasPort(pid))
                continue;
            RTLIL::SigSpec mapped = m_SigMap(a_Cell->getPort(pid));
            std::vector<RTLIL::SigBit> bits = mapped.bits();
            for (auto bit : bits) {
                if (bit.wire == nullptr)
                    continue;
                auto it = bit_users.find(bit);
                if (it != bit_users.end() && it->second > 0)
                    return true;
            }
        }
        return false;
    }

    /// Return true if any wire connected to one of the v2 SISD cell's ports
    /// carries a (* keep *) attribute. Such wires are explicit user requests
    /// to preserve a named signal; SIMD-packing would rename the carrier
    /// (data ports widen from 16/9/25 bits to 32/18/50 bits, and the source
    /// wire is rerouted through the new wider wrapper), erasing the kept
    /// name. Conservative: skip the cell, leave it as a SISD wrapper.
    bool isDspv2PortWireKept(RTLIL::Cell *a_Cell)
    {
        for (const auto &conn : a_Cell->connections()) {
            for (auto bit : conn.second.bits()) {
                if (bit.wire != nullptr && bit.wire->has_attribute(RTLIL::escape_id("keep"))) {
                    return true;
                }
            }
        }
        return false;
    }

    void executeDspv2(RTLIL::Design *a_Design)
    {
        for (auto module : a_Design->selected_modules()) {

            m_SigMap.clear();
            m_SigMap.set(module);

            // Build a per-canonical-bit consumer count for this module. A
            // bit's count is the number of cell-input ports + module-output
            // ports that read it. Cascade outputs of a v2 SISD candidate are
            // "active" (and the cell must NOT be SIMD-packed) iff any bit of
            // a_cout_o / b_cout_o / z_cout_o has count > 0 here.
            //
            // Note: SigSpec rvalues returned by m_SigMap(...) must be bound
            // to a named local before calling .bits(); range-for lifetime
            // extension only covers the outermost expression and clang -O3
            // has been observed to mis-elide the inner SigSpec, leaving the
            // bit-list referring to freed memory (the same UB that bit
            // ql_dsp -dspv2 input-register absorption earlier; see
            // ql-dsp.cc run_dspv2()).
            dict<RTLIL::SigBit, int> bit_users;
            for (auto cell2 : module->cells()) {
                for (auto &conn : cell2->connections()) {
                    if (!cell2->input(conn.first))
                        continue;
                    RTLIL::SigSpec mapped = m_SigMap(conn.second);
                    std::vector<RTLIL::SigBit> bits = mapped.bits();
                    for (auto bit : bits) {
                        if (bit.wire != nullptr)
                            bit_users[bit] += 1;
                    }
                }
            }
            for (auto wire : module->wires()) {
                if (!wire->port_output)
                    continue;
                RTLIL::SigSpec mapped = m_SigMap(RTLIL::SigSpec(wire));
                std::vector<RTLIL::SigBit> bits = mapped.bits();
                for (auto bit : bits) {
                    if (bit.wire != nullptr)
                        bit_users[bit] += 1;
                }
            }

            // Group dspv2_16x9x32_cfg_ports cells by their control-port +
            // cfg-param signature.
            dict<DspConfig, std::vector<RTLIL::Cell *>> groups;
            for (auto cell : module->selected_cells()) {

                if (cell->type != RTLIL::escape_id(m_Dspv2SisdType)) {
                    continue;
                }
                if (cell->has_keep_attr()) {
                    continue;
                }
                if (isDspv2PortWireKept(cell)) {
                    log("  SIMD(v2): skipping %s (port wire carries keep attribute)\n",
                        RTLIL::unescape_id(cell->name).c_str());
                    continue;
                }
                if (isDspv2CascadeActive(cell, bit_users)) {
                    log("  SIMD(v2): skipping %s (active cascade port)\n",
                        RTLIL::unescape_id(cell->name).c_str());
                    continue;
                }

                const auto key = getDspv2Config(cell);
                groups[key].push_back(cell);
            }

            std::vector<const RTLIL::Cell *> cellsToRemove;

            for (const auto &it : groups) {
                const auto &group = it.second;
                const auto &config = it.first;

                size_t count = group.size();
                if (count & 1)
                    count--; // pairs only

                for (size_t i = 0; i < count; i += 2) {
                    const RTLIL::Cell *dsp_a = group[i];     // low half
                    const RTLIL::Cell *dsp_b = group[i + 1]; // high half

                    std::string name = stringf("simdv2_%ld", i / 2);

                    log(" SIMD(v2): %s + %s => %s (%s)\n", RTLIL::unescape_id(dsp_a->name).c_str(),
                        RTLIL::unescape_id(dsp_b->name).c_str(), name.c_str(), m_Dspv2SimdType.c_str());

                    RTLIL::Cell *simd = module->addCell(RTLIL::escape_id(name), RTLIL::escape_id(m_Dspv2SimdType));
                    if (!simd->known()) {
                        log_error(" The target cell type '%s' is not known!", m_Dspv2SimdType.c_str());
                    }

                    // Connect common control ports (1:1 from the matched config).
                    for (const auto &it : m_Dspv2CfgPorts) {
                        auto sport = RTLIL::escape_id(it.first);
                        auto dport = RTLIL::escape_id(it.second);
                        simd->setPort(dport, config.connections.at(sport));
                    }

                    // Concatenate data ports low|high. Target widths are 2x
                    // source widths; if a source port is missing or narrower,
                    // pad inputs with Sx and outputs with new wires.
                    for (const auto &it : m_Dspv2DataPorts) {
                        auto sport = RTLIL::escape_id(it.first);
                        auto dport = RTLIL::escape_id(it.second);

                        size_t width;
                        bool isOutput;
                        std::tie(width, isOutput) = getPortInfo(simd, dport);

                        auto getConnection = [&](const RTLIL::Cell *cell) {
                            RTLIL::SigSpec sigspec;
                            if (cell->hasPort(sport)) {
                                sigspec.append(cell->getPort(sport));
                            }
                            if (sigspec.bits().size() < width / 2) {
                                if (isOutput) {
                                    for (size_t i = 0; i < width / 2 - sigspec.bits().size(); ++i) {
                                        sigspec.append(RTLIL::SigSpec());
                                    }
                                } else {
                                    sigspec.append(RTLIL::SigSpec(RTLIL::Sx, width / 2 - sigspec.bits().size()));
                                }
                            }
                            return sigspec;
                        };

                        RTLIL::SigSpec sigspec;
                        sigspec.append(getConnection(dsp_a));
                        sigspec.append(getConnection(dsp_b));
                        simd->setPort(dport, sigspec);
                    }

                    // Copy matched cfg-parameters from dsp_a (==dsp_b by
                    // construction).
                    for (const auto &name : m_Dspv2CfgParams) {
                        auto pname = RTLIL::escape_id(name);
                        if (dsp_a->hasParam(pname)) {
                            simd->setParam(pname, dsp_a->getParam(pname));
                        }
                    }

                    // COEFF_0: concatenate low|high. Source is 16 bits, target
                    // is 32 bits. Pad with zeros if a half is missing.
                    auto coeff_id = RTLIL::escape_id("COEFF_0");
                    RTLIL::Const coeff_a = dsp_a->hasParam(coeff_id) ? dsp_a->getParam(coeff_id) : RTLIL::Const(0, 16);
                    RTLIL::Const coeff_b = dsp_b->hasParam(coeff_id) ? dsp_b->getParam(coeff_id) : RTLIL::Const(0, 16);
                    std::vector<RTLIL::State> coeff_bits;
                    coeff_bits.insert(coeff_bits.end(), coeff_a.begin(), coeff_a.end());
                    coeff_bits.insert(coeff_bits.end(), coeff_b.begin(), coeff_b.end());
                    simd->setParam(coeff_id, RTLIL::Const(coeff_bits));

                    // Force fractured mode on the target.
                    simd->setParam(RTLIL::escape_id("FRAC_MODE"), RTLIL::Const(1, 1));

                    // Propagate is_inferred only if BOTH halves were inferred.
                    bool is_inferred_a = dsp_a->has_attribute(RTLIL::escape_id("is_inferred"))
                                           ? dsp_a->get_bool_attribute(RTLIL::escape_id("is_inferred"))
                                           : false;
                    bool is_inferred_b = dsp_b->has_attribute(RTLIL::escape_id("is_inferred"))
                                           ? dsp_b->get_bool_attribute(RTLIL::escape_id("is_inferred"))
                                           : false;
                    simd->set_bool_attribute(RTLIL::escape_id("is_inferred"), is_inferred_a && is_inferred_b);

                    cellsToRemove.push_back(dsp_a);
                    cellsToRemove.push_back(dsp_b);
                }
            }

            for (const auto &cell : cellsToRemove) {
                module->remove(const_cast<RTLIL::Cell *>(cell));
            }
        }

        m_SigMap.clear();
    }

} QlDspSimdPass;

PRIVATE_NAMESPACE_END
