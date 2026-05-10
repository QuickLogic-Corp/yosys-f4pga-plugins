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

#include "kernel/sigtools.h"
#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

#include "pmgen/ql-dsp-pm.h"

void create_ql_dsp(ql_dsp_pm &pm)
{
    auto &st = pm.st_ql_dsp;

    log("Checking %s.%s for QL DSP inference.\n", log_id(pm.module), log_id(st.mul));

    log_debug("ffA:    %s\n", log_id(st.ffA, "--"));
    log_debug("ffB:    %s\n", log_id(st.ffB, "--"));
    log_debug("ffCD:   %s\n", log_id(st.ffCD, "--"));
    log_debug("mul:    %s\n", log_id(st.mul, "--"));
    log_debug("ffFJKG: %s\n", log_id(st.ffFJKG, "--"));
    log_debug("ffH:    %s\n", log_id(st.ffH, "--"));
    log_debug("add:    %s\n", log_id(st.add, "--"));
    log_debug("mux:    %s\n", log_id(st.mux, "--"));
    log_debug("ffO:    %s\n", log_id(st.ffO, "--"));
    log_debug("\n");

    if (GetSize(st.sigA) > 16) {
        log("  input A (%s) is too large (%d > 16).\n", log_signal(st.sigA), GetSize(st.sigA));
        return;
    }

    if (GetSize(st.sigB) > 16) {
        log("  input B (%s) is too large (%d > 16).\n", log_signal(st.sigB), GetSize(st.sigB));
        return;
    }

    if (GetSize(st.sigO) > 33) {
        log("  adder/accumulator (%s) is too large (%d > 33).\n", log_signal(st.sigO), GetSize(st.sigO));
        return;
    }

    if (GetSize(st.sigH) > 32) {
        log("  output (%s) is too large (%d > 32).\n", log_signal(st.sigH), GetSize(st.sigH));
        return;
    }

    Cell *cell = st.mul;
    if (cell->type == ID($mul)) {
        log("  replacing %s with QL_DSP cell.\n", log_id(st.mul->type));

        cell = pm.module->addCell(NEW_ID, ID(QL_DSP));
        pm.module->swap_names(cell, st.mul);
    } else
        log_assert(cell->type == ID(QL_DSP));

    // QL_DSP Input Interface
    SigSpec A = st.sigA;
    A.extend_u0(16, st.mul->getParam(ID::A_SIGNED).as_bool());
    log_assert(GetSize(A) == 16);

    SigSpec B = st.sigB;
    B.extend_u0(16, st.mul->getParam(ID::B_SIGNED).as_bool());
    log_assert(GetSize(B) == 16);

    SigSpec CD = st.sigCD;
    if (CD.empty())
        CD = RTLIL::Const(0, 32);
    else
        log_assert(GetSize(CD) == 32);

    cell->setPort(ID::A, A);
    cell->setPort(ID::B, B);
    cell->setPort(ID::C, CD.extract(16, 16));
    cell->setPort(ID::D, CD.extract(0, 16));

    cell->setParam(ID(A_REG), st.ffA ? State::S1 : State::S0);
    cell->setParam(ID(B_REG), st.ffB ? State::S1 : State::S0);
    cell->setParam(ID(C_REG), st.ffCD ? State::S1 : State::S0);
    cell->setParam(ID(D_REG), st.ffCD ? State::S1 : State::S0);

    // QL_DSP Output Interface

    SigSpec O = st.sigO;
    int O_width = GetSize(O);
    if (O_width == 33) {
        log_assert(st.add);
        // If we have a signed multiply-add, then perform sign extension
        if (st.add->getParam(ID::A_SIGNED).as_bool() && st.add->getParam(ID::B_SIGNED).as_bool())
            pm.module->connect(O[32], O[31]);
        else
            cell->setPort(ID::CO, O[32]);
        O.remove(O_width - 1);
    } else
        cell->setPort(ID::CO, pm.module->addWire(NEW_ID));
    log_assert(GetSize(O) <= 32);
    if (GetSize(O) < 32)
        O.append(pm.module->addWire(NEW_ID, 32 - GetSize(O)));

    cell->setPort(ID::O, O);

    cell->setParam(ID::A_SIGNED, st.mul->getParam(ID::A_SIGNED).as_bool());
    cell->setParam(ID::B_SIGNED, st.mul->getParam(ID::B_SIGNED).as_bool());

    if (cell != st.mul)
        pm.autoremove(st.mul);
    else
        pm.blacklist(st.mul);
    pm.autoremove(st.ffFJKG);
    pm.autoremove(st.add);
}

struct QlDspPass : public Pass {
    QlDspPass() : Pass("ql_dsp", "ql: map multipliers") {}

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    ql_dsp [options] [selection]\n");
        log("\n");
        log("Map multipliers ($mul/QL_DSP) and multiply-accumulate ($mul/QL_DSP + $add)\n");
        log("cells into ql DSP resources.\n");
        log("Pack input registers (A, B, {C,D}), pipeline registers\n");
        log("({F,J,K,G}, H), output registers (O -- full 32-bits or lower 16-bits only); \n");
        log("and post-adder into into the QL_DSP resource.\n");
        log("\n");
        log("Multiply-accumulate operations using the post-adder with feedback on the {C,D}\n");
        log("input will be folded into the DSP. In this scenario only, resetting the\n");
        log("the accumulator to an arbitrary value can be inferred to use the {C,D} input.\n");
        log("\n");
        log("    -dspv2\n");
        log("        Operate on dspv2_*_cfg_ports cells (Aurora2 DSPv2 wrappers) instead\n");
        log("        of the legacy QL_DSP cell. Absorbs simple synchronous $dff input\n");
        log("        pipelines on a_i/b_i/c_i into the cell's A_REG/B_REG/C_REG cfg-\n");
        log("        parameters. Cascade folding (z_cout/z_cin) is intentionally NOT\n");
        log("        performed yet -- it is deferred to a follow-up commit per the\n");
        log("        DSPv2 flow. The legacy QL_DSP pmgen-driven path\n");
        log("        is unchanged when this option is omitted.\n");
        log("\n");
    }

    bool replace_existing_pass() const override
    {
        return true;
    }

    // ------------------------------------------------------------------
    // -dspv2 mode: absorb $dff input pipelines into the dspv2 wrapper's
    // A_REG / B_REG / C_REG cfg-parameters.
    //
    // A $dff is eligible if:
    //   - it drives the entire dspv2 cell port (a_i, b_i, or c_i);
    //   - its CLK signal is identical to the dspv2 cell's clock_i;
    //   - it has no async reset and no enable (plain $dff);
    //   - every bit of its Q has exactly one user (this cell port);
    //   - the corresponding cell parameter is currently 0 (no double-absorb).
    //
    // On absorption, the cell port is rewired to the $dff's D and the
    // matching cfg-parameter is set to 1. The $dff is removed.
    void run_dspv2(RTLIL::Design *design)
    {
        const std::vector<std::string> v2_types = {"dspv2_16x9x32_cfg_ports", "dspv2_32x18x64_cfg_ports"};
        // Cell input port -> cfg-parameter to set when the pipeline is absorbed.
        const std::vector<std::pair<std::string, std::string>> port_to_param = {
          std::make_pair("a_i", "A_REG"),
          std::make_pair("b_i", "B_REG"),
          std::make_pair("c_i", "C_REG"),
        };

        for (auto module : design->selected_modules()) {
            SigMap sigmap(module);

            // Count fan-out per SigBit, restricted to *consumer-side* cell-port
            // references. Cell::input/output correctly handles both built-in
            // cells (via yosys_celltypes) and user-defined modules (via
            // module->design->module(type)->wire(port)->port_input), so this
            // gives accurate single-consumer detection.
            //
            // Note: a SigSpec rvalue returned by sigmap() must be bound to a
            // named local before iterating .bits(). Range-for lifetime
            // extension only covers the outermost expression, and clang -O3
            // has been observed to mis-elide the inner SigSpec, leaving the
            // bit-list referring to freed memory and the loop body silently
            // skipped. This was the actual root cause of the original
            // input-register absorption failure on the aurora2 toolchain.
            dict<RTLIL::SigBit, int> bit_users;
            for (auto cell : module->cells()) {
                for (auto &conn : cell->connections()) {
                    if (!cell->input(conn.first))
                        continue;
                    RTLIL::SigSpec mapped = sigmap(conn.second);
                    std::vector<RTLIL::SigBit> bits = mapped.bits();
                    for (auto bit : bits) {
                        if (bit.wire != nullptr)
                            bit_users[bit] += 1;
                    }
                }
            }

            // Pre-build a SigBit -> driver (cell, output-port) map. Avoids the
            // original code's nested O(B*C) re-scan per absorbed bit. Same
            // named-local lifetime discipline as above.
            dict<RTLIL::SigBit, std::pair<RTLIL::Cell *, RTLIL::IdString>> bit_driver;
            for (auto cell : module->cells()) {
                for (auto &conn : cell->connections()) {
                    if (!cell->output(conn.first))
                        continue;
                    RTLIL::SigSpec mapped = sigmap(conn.second);
                    std::vector<RTLIL::SigBit> bits = mapped.bits();
                    for (auto bit : bits) {
                        if (bit.wire != nullptr)
                            bit_driver[bit] = std::make_pair(cell, conn.first);
                    }
                }
            }

            std::vector<RTLIL::Cell *> ffs_to_remove;

            for (auto cell : module->selected_cells()) {
                if (std::find(v2_types.begin(), v2_types.end(), cell->type.str().substr(1)) == v2_types.end()) {
                    continue;
                }
                if (cell->has_keep_attr()) {
                    continue;
                }
                if (!cell->hasPort(RTLIL::escape_id("clock_i"))) {
                    continue;
                }
                RTLIL::SigSpec cell_clk = sigmap(cell->getPort(RTLIL::escape_id("clock_i")));
                if (cell_clk.size() != 1) {
                    continue;
                }
                RTLIL::SigBit cell_clk_bit = cell_clk[0];

                // Cell-level global reset(active-high). This
                // is the only reset path the cell offers for its A/B/C input
                // pipeline registers, so async/sync FFs whose reset signal
                // does NOT match this net cannot be absorbed without
                // changing the netlist's reset semantics.
                RTLIL::SigBit cell_rst_bit;
                bool cell_has_rst = false;
                if (cell->hasPort(RTLIL::escape_id("reset_i"))) {
                    RTLIL::SigSpec cell_rst = sigmap(cell->getPort(RTLIL::escape_id("reset_i")));
                    if (cell_rst.size() == 1) {
                        cell_rst_bit = cell_rst[0];
                        cell_has_rst = true;
                    }
                }

                for (const auto &pp : port_to_param) {
                    auto port = RTLIL::escape_id(pp.first);
                    auto param = RTLIL::escape_id(pp.second);

                    if (!cell->hasPort(port))
                        continue;
                    if (cell->hasParam(param) && cell->getParam(param).as_bool())
                        continue; // already absorbed once

                    RTLIL::SigSpec port_sig = cell->getPort(port);
                    if (port_sig.empty())
                        continue;

                    RTLIL::SigSpec mapped_port = sigmap(port_sig);
                    std::vector<RTLIL::SigBit> port_bits = mapped_port.bits();

                    // Every bit must come from a Q port of the same FF cell,
                    // on the same clock as the dspv2 cell, that single FF
                    // cell must be the unique consumer of all those Q bits,
                    // and the FF type must be one we know how to absorb
                    // ($dff, $dffe, $sdff, $adff, $adffe). Per-flavour
                    // semantic filters (EN constant-active, RST polarity /
                    // value / source net) are applied below once we know
                    // the candidate FF.
                    RTLIL::Cell *ff = nullptr;
                    bool eligible = true;

                    for (auto bit : port_bits) {
                        if (bit.wire == nullptr) {
                            eligible = false;
                            break;
                        }
                        // A bit that escapes the module via an output port
                        // is not safely absorbable -- another module observes
                        // the registered value.
                        if (bit.wire->port_output) {
                            eligible = false;
                            break;
                        }
                        // O(1) driver lookup via the pre-built map.
                        auto dit = bit_driver.find(bit);
                        if (dit == bit_driver.end()) {
                            eligible = false;
                            break;
                        }
                        RTLIL::Cell *driver = dit->second.first;
                        RTLIL::IdString driver_port = dit->second.second;
                        if (driver_port != ID(Q)) {
                            eligible = false;
                            break;
                        }
                        if (driver->type != ID($dff) &&
                            driver->type != ID($dffe) &&
                            driver->type != ID($sdff) &&
                            driver->type != ID($adff) &&
                            driver->type != ID($adffe)) {
                            eligible = false;
                            break;
                        }
                        if (ff == nullptr)
                            ff = driver;
                        else if (ff != driver) {
                            eligible = false;
                            break;
                        }
                        // The Q bit must have exactly one consumer (this cell port).
                        if (bit_users[bit] != 1) {
                            eligible = false;
                            break;
                        }
                    }

                    if (!eligible || ff == nullptr)
                        continue;

                    // Honour the user's \keep attribute: never remove a $dff
                    // that the designer (or upstream pass) has explicitly
                    // marked. Mirrors v1 ql_dsp.pmg in_dffe semantics: check
                    // both the cell attribute and the Q-side wire chunks.
                    if (ff->has_keep_attr())
                        continue;
                    {
                        bool keep_hit = false;
                        RTLIL::SigSpec ff_q_raw = ff->getPort(ID(Q));
                        for (auto chunk : ff_q_raw.chunks()) {
                            if (chunk.wire && chunk.wire->get_bool_attribute(ID(keep))) {
                                keep_hit = true;
                                break;
                            }
                        }
                        if (keep_hit)
                            continue;
                    }

                    // Reject if the Q wire carries a non-zero/non-undef \init
                    // attribute. The $dff is removed entirely on absorption,
                    // so an init value would be silently dropped.
                    {
                        bool init_ok = true;
                        RTLIL::SigSpec ff_q_raw = ff->getPort(ID(Q));
                        for (auto chunk : ff_q_raw.chunks()) {
                            if (chunk.wire == nullptr)
                                continue;
                            auto ait = chunk.wire->attributes.find(ID(init));
                            if (ait == chunk.wire->attributes.end())
                                continue;
                            const RTLIL::Const &init = ait->second;
                            if (!init.is_fully_undef() && !init.is_fully_zero()) {
                                init_ok = false;
                                break;
                            }
                        }
                        if (!init_ok)
                            continue;
                    }

                    // Verify clock identity. CLK_POLARITY must be active-high
                    // because the cell's clock_i is positive-edge.
                    if (!ff->getParam(ID(CLK_POLARITY)).as_bool())
                        continue;
                    RTLIL::SigSpec ff_clk = sigmap(ff->getPort(ID(CLK)));
                    if (ff_clk.size() != 1 || ff_clk[0] != cell_clk_bit)
                        continue;

                    // Per-FF-flavour semantic filters. The dspv2 cell
                    // has no per-pipeline-register enable port and only one
                    // active-high global reset (cell.reset_i).
                    // For every $dffe / $sdff / $adff / $adffe flavour we
                    // therefore require:
                    //   - EN (if present) is provably tied to a constant
                    //     matching EN_POLARITY (i.e. always-active). A
                    //     variable enable cannot be preserved.
                    //   - Async/Sync reset (if present) has *RST_POLARITY=1,
                    //     *RST_VALUE fully zero, and *RST signal == cell's
                    //     reset_i net. Otherwise the cell-level global reset
                    //     would not reproduce the FF's reset behaviour.
                    // Plain $dff has no reset/enable and is always accepted
                    // here (the prior $dff-only matcher's behaviour).
                    {
                        bool flavour_ok = true;
                        if (ff->type == ID($dffe) || ff->type == ID($adffe)) {
                            if (!ff->hasPort(ID(EN)) || !ff->hasParam(ID(EN_POLARITY))) {
                                flavour_ok = false;
                            } else {
                                RTLIL::SigSpec en_sig = sigmap(ff->getPort(ID(EN)));
                                bool en_pol = ff->getParam(ID(EN_POLARITY)).as_bool();
                                // EN must be exactly one bit and a constant
                                // matching EN_POLARITY (so the FF is always
                                // enabled). A variable EN cannot be folded
                                // because the cell has no per-input EN port.
                                RTLIL::State expected = en_pol ? RTLIL::State::S1 : RTLIL::State::S0;
                                if (en_sig.size() != 1 || en_sig[0] != RTLIL::SigBit(expected))
                                    flavour_ok = false;
                            }
                        }

                        if (flavour_ok && (ff->type == ID($adff) || ff->type == ID($adffe))) {
                            if (!cell_has_rst) {
                                flavour_ok = false;
                            } else if (!ff->hasPort(ID(ARST)) || !ff->hasParam(ID(ARST_POLARITY)) ||
                                       !ff->hasParam(ID(ARST_VALUE))) {
                                flavour_ok = false;
                            } else if (!ff->getParam(ID(ARST_POLARITY)).as_bool()) {
                                flavour_ok = false;
                            } else if (!ff->getParam(ID(ARST_VALUE)).is_fully_zero()) {
                                flavour_ok = false;
                            } else {
                                RTLIL::SigSpec arst_sig = sigmap(ff->getPort(ID(ARST)));
                                if (arst_sig.size() != 1 || arst_sig[0] != cell_rst_bit)
                                    flavour_ok = false;
                            }
                        }

                        if (flavour_ok && ff->type == ID($sdff)) {
                            if (!cell_has_rst) {
                                flavour_ok = false;
                            } else if (!ff->hasPort(ID(SRST)) || !ff->hasParam(ID(SRST_POLARITY)) ||
                                       !ff->hasParam(ID(SRST_VALUE))) {
                                flavour_ok = false;
                            } else if (!ff->getParam(ID(SRST_POLARITY)).as_bool()) {
                                flavour_ok = false;
                            } else if (!ff->getParam(ID(SRST_VALUE)).is_fully_zero()) {
                                flavour_ok = false;
                            } else {
                                RTLIL::SigSpec srst_sig = sigmap(ff->getPort(ID(SRST)));
                                if (srst_sig.size() != 1 || srst_sig[0] != cell_rst_bit)
                                    flavour_ok = false;
                            }
                        }

                        if (!flavour_ok)
                            continue;
                    }

                    // The FF's Q must be exactly the cell's port spec
                    // (modulo the SigMap canonicalisation used above).
                    RTLIL::SigSpec ff_q = sigmap(ff->getPort(ID(Q)));
                    if (ff_q.size() != port_sig.size())
                        continue;
                    if (ff_q != sigmap(port_sig))
                        continue;

                    // Absorb: rewire port to D, set cfg-param, drop FF.
                    log("Absorbing $dff %s into %s.%s on cell %s\n",
                        log_id(ff), log_id(cell->type), pp.first.c_str(), log_id(cell));
                    cell->setPort(port, ff->getPort(ID(D)));
                    cell->setParam(param, RTLIL::Const(1, 1));
                    ffs_to_remove.push_back(ff);
                }
            }

            // De-duplicate (an FF could only be matched once given the fan-out
            // constraint above, but keep the std::sort / unique idiom for safety).
            std::sort(ffs_to_remove.begin(), ffs_to_remove.end());
            ffs_to_remove.erase(std::unique(ffs_to_remove.begin(), ffs_to_remove.end()), ffs_to_remove.end());
            for (auto ff : ffs_to_remove) {
                module->remove(ff);
            }
        }
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        log_header(design, "Executing ql_DSP pass (map multipliers).\n");

        bool dspv2 = false;
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-dspv2") {
                dspv2 = true;
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        if (dspv2) {
            run_dspv2(design);
            return;
        }

        for (auto module : design->selected_modules())
            ql_dsp_pm(module, module->selected_cells()).run_ql_dsp(create_ql_dsp);
    }
} QlDspPass;

PRIVATE_NAMESPACE_END
