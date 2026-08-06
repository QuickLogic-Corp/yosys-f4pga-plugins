/*
 * Copyright 2020-2026 F4PGA Authors
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
 * ql_dspv2_to_dspv4 - DSP-V2 -> DSP-V4 synthesis pass (Synplify flow, Phase 1).
 *
 * Input : generic `QL_DSPV2` hard-block cells (exactly what Synplify Pro emits),
 *         with a constant 80-bit MODE_BITS parameter and constant
 *         feedback/output_select ports.
 * Output: generic monolithic `QL_DSP4` base cells carrying the translated V4
 *         configuration word (OPMODE/ALUMODE/INMODE/... as parameters), plus
 *         cascade-pair fusion of a CONCAT_CASCADE feeding a MULTADD /
 *         PREADDER_MULTADD into a single QL_DSP4 using the native 50-bit C input.
 *
 * This runs *in place of* `ql_dspv2_types` on the V4 path. It reuses that pass's
 * recognition mechanism (constant feedback/output_select + MODE_BITS decode ->
 * control word).
 *
 * References (committed on aurora2 master):
 *   docs/development/DSPV2-to-DSPV4-Synthesis/DSPV4_SYNPLIFY_PHASE1_REQUIREMENTS.md
 *   - Appendix A: control words per Phase-1 mode
 *   - Appendix B: fusion reproducibility table (addend delay k <= 1 fuses)
 * RTL is the single source of truth (behavioral_model/dspv4_sim.v -> dsp4_top).
 */

#include "kernel/rtlil.h"
#include "kernel/sigtools.h"
#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// ---------------------------------------------------------------------------
// V2 recognition (mirrors ql_dspv2_types.cc)
// ---------------------------------------------------------------------------

// MODE_BITS[79:0] field decode (see ql_dspv2_types.cc:1009-1077 / dspv2_sim.v).
struct V2Config {
    int coeff0;      // [31:0]
    int acc_fir;     // [37:32]
    int round;       // [40:38]
    int zc_shift;    // [45:41]
    int zreg_shift;  // [50:46]
    int shift_reg;   // [56:51]
    bool saturate;   // [57]
    bool subtract;   // [58]
    bool pre_add;    // [59]
    bool a_sel;      // [60]
    bool a_reg;      // [61]
    bool a1_reg;     // [62]
    bool a2_reg;     // [63]
    bool b_sel;      // [64]
    bool b_reg;      // [65]
    bool b1_reg;     // [66]
    bool b2_reg;     // [67]
    bool c_reg;      // [68]
    bool bc_reg;     // [69]
    bool m_reg;      // [70]
    bool zcin_reg;   // [71] (a.k.a. ZCIN_SEL)
    bool acout_sel;  // [72]
    bool bcout_sel;  // [73]
    bool frac_mode;  // [79]
    // Not from MODE_BITS: output register, encoded in output_select[2]
    // (output_select >= 4). Set from the port in execute().
    bool out_reg = false;
};

enum class V2Mode { MULT, MULTACC, MULTACC_NEG, MULTADD, MULTADD_NEG, PREADDER_MULT, PREADDER_MULTADD, CONCAT_CASCADE, UNKNOWN };

static const char *mode_name(V2Mode m)
{
    switch (m) {
    case V2Mode::MULT: return "MULT";
    case V2Mode::MULTACC: return "MULTACC";
    case V2Mode::MULTACC_NEG: return "MULTACC_NEG";
    case V2Mode::MULTADD: return "MULTADD";
    case V2Mode::MULTADD_NEG: return "MULTADD_NEG";
    case V2Mode::PREADDER_MULT: return "PREADDER_MULT";
    case V2Mode::PREADDER_MULTADD: return "PREADDER_MULTADD";
    case V2Mode::CONCAT_CASCADE: return "CONCAT_CASCADE";
    default: return "UNKNOWN";
    }
}

struct QlDspV2ToV4Pass : public Pass {
    QlDspV2ToV4Pass() : Pass("ql_dspv2_to_dspv4", "DSP-V2 -> DSP-V4 conversion (Synplify flow, Phase 1)") {}

    bool replace_existing_pass() const override { return true; }

    void help() override
    {
        log("\n");
        log("    ql_dspv2_to_dspv4 [selection]\n");
        log("\n");
        log("Convert generic QL_DSPV2 DSP hard-block cells (as emitted by Synplify)\n");
        log("into DSP-V4 form. Emits generic monolithic QL_DSP4 base cells with the\n");
        log("translated V4 configuration word, and fuses a CONCAT_CASCADE feeding a\n");
        log("MULTADD/PREADDER_MULTADD into a single QL_DSP4 (routing the concatenated\n");
        log("50-bit operand to the native C input).\n");
        log("\n");
        log("Runs in place of ql_dspv2_types on the V4 (-dspv4) path. Hard-errors on\n");
        log("V2-only configuration with no V4 analogue, on unmappable cells, and on\n");
        log("fusion whose addend latency the V4 C path cannot reproduce (k >= 2).\n");
        log("\n");
    }

    // ---- constant-net analysis ---------------------------------------------

    // Map VCC/GND driver-cell outputs to constant bits. Synplify drives the
    // constant control ports (feedback/output_select) with VCC/GND cells rather
    // than literal constants, so those must be resolved before reading the port.
    // Mirrors ql_dspv2_types::build_const_drivers.
    static void build_const_drivers(RTLIL::Module *module, SigMap &sigmap, dict<SigBit, State> &const_drivers)
    {
        for (auto *drv : module->cells()) {
            if (drv->type == ID(VCC)) {
                for (auto &bit : sigmap(drv->getPort(ID(P))))
                    const_drivers[bit] = State::S1;
            } else if (drv->type == ID(GND)) {
                for (auto &bit : sigmap(drv->getPort(ID(G))))
                    const_drivers[bit] = State::S0;
            }
        }
    }

    // Read a constant-driven port into an unsigned int, resolving VCC/GND driver
    // cells through const_drivers. Mirrors ql_dspv2_types::get_const_port_value.
    static int get_const_port(RTLIL::Cell *cell, RTLIL::IdString port, SigMap &sigmap, const dict<SigBit, State> &const_drivers)
    {
        if (!cell->hasPort(port))
            return 0;
        RTLIL::SigSpec sig = sigmap(cell->getPort(port));
        for (auto &bit : sig) {
            auto it = const_drivers.find(bit);
            if (it != const_drivers.end())
                bit = SigBit(it->second);
        }
        if (!sig.is_fully_const())
            log_error("ql_dspv2_to_dspv4: cell %s port %s is not constant (%s); the pass requires "
                      "constant control ports.\n",
                      log_id(cell->name), log_id(port), log_signal(sig));
        return sig.as_const().as_int();
    }

    static V2Config decode_mode_bits(RTLIL::Cell *cell)
    {
        RTLIL::Const mb = cell->getParam(ID(MODE_BITS));
        V2Config c;
        c.coeff0 = mb.extract(0, 32).as_int(); // COEFF_0[31:0] is 32 bits
        c.acc_fir = mb.extract(32, 6).as_int();
        c.round = mb.extract(38, 3).as_int();
        c.zc_shift = mb.extract(41, 5).as_int();
        c.zreg_shift = mb.extract(46, 5).as_int();
        c.shift_reg = mb.extract(51, 6).as_int();
        c.saturate = mb.extract(57).as_bool();
        c.subtract = mb.extract(58).as_bool();
        c.pre_add = mb.extract(59).as_bool();
        c.a_sel = mb.extract(60).as_bool();
        c.a_reg = mb.extract(61).as_bool();
        c.a1_reg = mb.extract(62).as_bool();
        c.a2_reg = mb.extract(63).as_bool();
        c.b_sel = mb.extract(64).as_bool();
        c.b_reg = mb.extract(65).as_bool();
        c.b1_reg = mb.extract(66).as_bool();
        c.b2_reg = mb.extract(67).as_bool();
        c.c_reg = mb.extract(68).as_bool();
        c.bc_reg = mb.extract(69).as_bool();
        c.m_reg = mb.extract(70).as_bool();
        c.zcin_reg = mb.extract(71).as_bool();
        c.acout_sel = mb.extract(72).as_bool();
        c.bcout_sel = mb.extract(73).as_bool();
        c.frac_mode = mb.extract(79).as_bool();
        return c;
    }

    // control word: [7:5]=feedback [4:3]=output_select[1:0] [2]=zcin [1]=preadd [0]=sub
    static uint32_t control_word(int feedback, int output_select, const V2Config &c)
    {
        uint32_t w = 0;
        w |= (uint32_t(feedback) & 0x7) << 5;
        w |= (uint32_t(output_select) & 0x3) << 3;
        w |= (c.zcin_reg ? 1u : 0u) << 2;
        w |= (c.pre_add ? 1u : 0u) << 1;
        w |= (c.subtract ? 1u : 0u);
        return w;
    }

    static V2Mode classify(uint32_t cw)
    {
        switch (cw) {
        case 0b00000000:
            return V2Mode::MULT;
        case 0b00001000:
            return V2Mode::MULTACC;
        case 0b00001001:
            return V2Mode::MULTACC_NEG;
        case 0b00000010: // add
        case 0b00000011: // pre-adder subtract
            return V2Mode::PREADDER_MULT;
        case 0b01010000:
        case 0b01011000:
            return V2Mode::CONCAT_CASCADE;
        case 0b01110100:
        case 0b01111100:
            return V2Mode::MULTADD;
        case 0b01110101:
        case 0b01111101:
            return V2Mode::MULTADD_NEG;
        case 0b01110110:
        case 0b01111110:
            return V2Mode::PREADDER_MULTADD;
        default:
            return V2Mode::UNKNOWN;
        }
    }

    // ---- V2-only config hard error (P1-FR-6 / MM-5 / MM-6) -----------------
    static void check_v2_only_config(RTLIL::Cell *cell, const V2Config &c)
    {
        if (c.coeff0 != 0)
            log_error("ql_dspv2_to_dspv4: cell %s uses COEFF_0 (=%d) which has no DSP-V4 analogue (MM-5).\n", log_id(cell->name), c.coeff0);
        if (c.acc_fir != 0)
            log_error("ql_dspv2_to_dspv4: cell %s uses ACC_FIR (=%d) which has no DSP-V4 analogue (MM-5).\n", log_id(cell->name), c.acc_fir);
        if (c.frac_mode)
            log_error("ql_dspv2_to_dspv4: cell %s uses FRAC_MODE (fracturable 16x9) which has no DSP-V4 analogue (MM-6).\n", log_id(cell->name));
        if (c.zc_shift != 0)
            log_error("ql_dspv2_to_dspv4: cell %s uses ZC_SHIFT (=%d) which has no DSP-V4 analogue (MM-5).\n", log_id(cell->name), c.zc_shift);
        if (c.zreg_shift != 0)
            log_error("ql_dspv2_to_dspv4: cell %s uses ZREG_SHIFT (=%d) which has no DSP-V4 analogue (MM-5).\n", log_id(cell->name), c.zreg_shift);
        // A_SEL/B_SEL select the dedicated cascade input (a_cin/b_cin) over the
        // general-routing a/b (dspv2_sim.v:1287-1288). The A/B cascade chain is out
        // of Phase-1 scope and ACIN/BCIN are left untied, so a set A_SEL/B_SEL would
        // silently select a floating input -> hard error (P1-FR-6).
        if (c.a_sel)
            log_error("ql_dspv2_to_dspv4: cell %s sets A_SEL (uses the a_cin cascade input), which is out of "
                      "Phase-1 scope (A/B cascade not supported; ACIN is not connected).\n",
                      log_id(cell->name));
        if (c.b_sel)
            log_error("ql_dspv2_to_dspv4: cell %s sets B_SEL (uses the b_cin cascade input), which is out of "
                      "Phase-1 scope (A/B cascade not supported; BCIN is not connected).\n",
                      log_id(cell->name));
    }

    // DSP-V4 has no dynamic accumulate-load control (no load_acc-equivalent), so
    // an accumulate mode may only be produced when V2 load_acc is a constant. A
    // non-constant (variable) load_acc means the design relies on cycle-by-cycle
    // accumulate gating that V4 cannot represent -> unsupported (P1-FR-6).
    static void require_const_load_acc(RTLIL::Cell *cell, SigMap &sigmap, const dict<SigBit, State> &const_drivers)
    {
        if (!cell->hasPort(ID(load_acc)))
            return;
        SigSpec la = sigmap(cell->getPort(ID(load_acc)));
        for (auto &bit : la) {
            auto it = const_drivers.find(bit);
            if (it != const_drivers.end())
                bit = SigBit(it->second);
        }
        if (!la.is_fully_const())
            log_error("ql_dspv2_to_dspv4: cell %s is an accumulate mode with a non-constant load_acc (%s). "
                      "DSP-V4 has no dynamic accumulate-load control, so this mode is not supported; "
                      "load_acc must be a constant (P1-FR-6).\n",
                      log_id(cell->name), log_signal(la));
    }

    // Number of register stages DSP-V2 puts on the A / B multiply operand, decoded
    // from ALL three V2 register bits (matches dspv2_sim.v :1319-1320):
    //   a = A_REG              ? r_a1            -> 1 stage
    //       : (A1_REG&&A2_REG) ? r_a2 (2 deep)   -> 2 stages
    //       : A2_REG           ? r_a2 (1 deep)   -> 1 stage
    //       :                    a_acin          -> 0 stages
    // The V4 side reproduces this COUNT (see set_reg_params); the individual V2
    // bits are NOT copied, because V4's two enable bits are not per-stage -- the
    // PATH_OUT operand delay is (AREG0,AREG1)=(0,0)->0 (0,1)->1 (1,0)->0 (1,1)->2.
    // Also used for the fusion addend-latency check.
    static int a_stages(const V2Config &c) { return c.a_reg ? 1 : (c.a1_reg && c.a2_reg ? 2 : (c.a2_reg ? 1 : 0)); }
    static int b_stages(const V2Config &c) { return c.b_reg ? 1 : (c.b1_reg && c.b2_reg ? 2 : (c.b2_reg ? 1 : 0)); }

    // ---- QL_DSP4 emission helpers ------------------------------------------

    static RTLIL::Const c9(uint32_t v) { return RTLIL::Const(int(v), 9); }
    static RTLIL::Const c2(uint32_t v) { return RTLIL::Const(int(v), 2); }
    static RTLIL::Const c5(uint32_t v) { return RTLIL::Const(int(v), 5); }
    static RTLIL::Const c3(uint32_t v) { return RTLIL::Const(int(v), 3); }
    static RTLIL::Const c6(uint32_t v) { return RTLIL::Const(int(v), 6); }
    static RTLIL::Const c1(bool v) { return RTLIL::Const(v ? 1 : 0, 1); }

    // The QL_DSP4 output ports (everything else on the cell is an input). Used by
    // the cascade-fanout legalizer to find the cell driving a cascade net and to
    // clone a feeder with fresh, private outputs.
    static const pool<RTLIL::IdString> &dsp4_output_ports()
    {
        static const pool<RTLIL::IdString> ports = {ID(P),     ID(ACOUT),    ID(BCOUT), ID(PCOUT),
                                                    ID(CCOUT), ID(SIGNCOUT), ID(COUT)};
        return ports;
    }

    // The QL_DSP4 input that carries the ALU addend over the tile's dedicated
    // pcin_i cascade: PCIN, selected by OPMODE Z=001 (per-cell MULTADD). Any net on
    // this port MUST be point-to-point (fanout 1) -- pcin_i has no general-routing
    // connectivity (fc_val=0) and its only source is the dsp_p_chain <direct> from
    // exactly one adjacent dsp.pcout_o, so VPR aborts placement ("appears in 2
    // placement macros") if two chain heads share it.
    //
    // Z=011 (C, the fused CONCAT+MULTADD addend) is deliberately NOT a cascade
    // port. C enters the tile on general routing -- dsp_wrapper.c_i is fed from the
    // I* buses at fc_val=0.15 -- so a shared (or constant) C net is legal, needs no
    // replication, and must not be rejected here. A fused pair collapses into a
    // single QL_DSP4, so there is no inter-cell cascade left to constrain: A/B carry
    // the operands and C carries the addend, all on general routing.
    //
    // Returns an empty IdString for cells with no dedicated cascade addend
    // (Z=C, Z=ACC feedback, or Z open).
    static RTLIL::IdString cascade_addend_port(RTLIL::Cell *dsp)
    {
        if (dsp->type != ID(QL_DSP4) || !dsp->hasParam(ID(OPMODE)))
            return RTLIL::IdString();
        RTLIL::Const om = dsp->getParam(ID(OPMODE));
        if (GetSize(om) < 7)
            return RTLIL::IdString();
        int zsel = om.extract(4, 3).as_int(); // OPMODE[6:4]
        if (zsel == 1)                         // 001 = PCIN
            return ID(PCIN);
        return RTLIL::IdString();
    }

    // Set the register-config parameters common to per-cell and fused cells.
    // A/B input registers: reproduce the V2 operand register COUNT (a_stages/
    // b_stages, which fold A_REG/A1_REG/A2_REG) on the V4 operand path. V4's two
    // enable bits are not per-stage; the PATH_OUT delay is (AREG0,AREG1)=(0,0)->0
    // (0,1)->1 (1,1)->2, so n stages -> AREG1=(n>=1), AREG0=(n>=2). INMODE[0]/[4]
    // are left 0 -- they steer the pre-adder GATE_OUT path, not the operand delay.
    void set_reg_params(RTLIL::Cell *dsp, const V2Config &c, bool accumulate, int creg)
    {
        int na = a_stages(c), nb = b_stages(c);
        dsp->setParam(ID(AREG0), c1(na >= 2));
        dsp->setParam(ID(AREG1), c1(na >= 1));
        dsp->setParam(ID(BREG0), c1(nb >= 2));
        dsp->setParam(ID(BREG1), c1(nb >= 1));
        dsp->setParam(ID(MREG), c1(c.m_reg));
        dsp->setParam(ID(DREG), c1(c.c_reg));   // V2 pre-adder operand reg (C_REG) -> V4 D reg
        dsp->setParam(ID(ADREG), c1(c.bc_reg)); // V2 pre-adder OUTPUT reg (BC_REG) -> V4 AD reg
                                                // (dspv2_sim.v:1353 preadd=bc_reg?preadd_sat_r:preadd_sat
                                                //  == dspv4_sim.v:520 preadd_r_sel=ADREG?preadd_sat_r:preadd_sat)
        dsp->setParam(ID(CREG), c1(creg != 0));
        dsp->setParam(ID(COUTREG), c1(false));
        // PREG: required (=1) for any P-feedback accumulate mode (holds the
        // accumulator), and also serves as the single V2 output register
        // (output_select[2]) for non-accumulate modes. When BOTH accumulate AND the
        // V2 output register are present, PREG is taken by the accumulator and the
        // extra output stage is materialised as an external dffre on P (see
        // add_output_dffre / emit_per_cell).
        dsp->setParam(ID(PREG), c1(accumulate || c.out_reg));
        dsp->setParam(ID(A_IN_SEL), c1(c.a_sel));
        dsp->setParam(ID(B_IN_SEL), c1(c.b_sel));
        dsp->setParam(ID(A_COUT_SEL), c1(c.acout_sel));
        dsp->setParam(ID(B_COUT_SEL), c1(c.bcout_sel));
    }

    // Set the RSS (round/shift/saturate) config from V2 MODE_BITS (P1-FR-13).
    void set_rss_params(RTLIL::Cell *dsp, const V2Config &c)
    {
        bool rss_active = (c.round != 0) || (c.shift_reg != 0) || c.saturate;
        dsp->setParam(ID(USE_RSS), c1(rss_active));
        dsp->setParam(ID(ROUND), c3(c.round));
        dsp->setParam(ID(SHIFT), c6(c.shift_reg));
        dsp->setParam(ID(SATURATE), c1(c.saturate));
    }

    // Insert a per-bit output register (dffre) after the QL_DSP4 P output. Used
    // when a V2 accumulate mode ALSO carries the V2 output register
    // (output_select>=4): PREG holds the accumulator, so V4 has no internal slot
    // for the extra output-register stage (V2's z1) -- it is materialised as an
    // external dffre on P (mirrors ql_dspv2_types' external Z register). clk/reset
    // come from the V2 source cell (reset active-high). Constant/padding P bits are
    // passed through unregistered.
    void add_output_dffre(RTLIL::Module *module, RTLIL::Cell *dsp, RTLIL::Cell *src)
    {
        SigSpec pnet = dsp->getPort(ID(P)); // currently drives the original z net
        SigSpec clk = src->hasPort(ID(clk)) ? src->getPort(ID(clk)) : SigSpec(State::S0);
        SigSpec rst = src->hasPort(ID(reset)) ? src->getPort(ID(reset)) : SigSpec(State::S0);
        SigSpec new_p;
        for (int i = 0; i < GetSize(pnet); i++) {
            if (pnet[i].wire == nullptr) { // constant (e.g. zero-padding): no register
                new_p.append(pnet[i]);
                continue;
            }
            RTLIL::Wire *w = module->addWire(module->uniquify(stringf("\\%s_pout%d", log_id(dsp->name), i)), 1);
            new_p.append(SigBit(w));
            RTLIL::Cell *dff = module->addCell(module->uniquify(IdString("\\dffre")), IdString("\\dffre"));
            dff->setPort(IdString("\\D"), SigSpec(w));
            dff->setPort(IdString("\\Q"), pnet[i]);
            dff->setPort(IdString("\\C"), clk);
            dff->setPort(IdString("\\R"), rst);
            dff->setPort(IdString("\\E"), SigSpec());
        }
        dsp->setPort(ID(P), new_p); // DSP now drives the intermediate wires; dffres drive z
    }

    // Return ~sig. Folds to a constant when sig is fully constant (the common
    // case: Synplify ties reset / acc_reset / load_acc to a constant), so no dead
    // $not cell is emitted; otherwise emits a $not.
    static SigSpec invert(RTLIL::Module *module, SigSpec sig)
    {
        if (sig.is_fully_const()) {
            RTLIL::Const c = sig.as_const();
            for (auto &b : c.bits())
                b = (b == State::S1) ? State::S0 : (b == State::S0 ? State::S1 : b);
            return c;
        }
        return module->Not(NEW_ID, sig);
    }

    // Connect the clock / reset / clock-enable ports of a new QL_DSP4 from a V2
    // source cell. V2 reset/acc_reset are active-HIGH; V4 RSTN/ACCRSTN are
    // active-LOW, so they are inverted here.
    void connect_clocking(RTLIL::Module *module, RTLIL::Cell *dsp, RTLIL::Cell *src)
    {
        SigSpec one = State::S1;
        dsp->setPort(ID(CLK), src->hasPort(ID(clk)) ? src->getPort(ID(clk)) : SigSpec(State::S0));
        // active-high V2 reset -> active-low V4 RSTN (RSTN = ~reset); default
        // (no port) is 1 = inactive. Constant resets fold to a constant (no $not).
        dsp->setPort(ID(RSTN), src->hasPort(ID(reset)) ? invert(module, src->getPort(ID(reset))) : one);
        // V2 acc_reset (synchronous accumulator clear, active-HIGH) -> V4 ACCRSTN
        // (synchronous accumulator reset, active-LOW): ACCRSTN = ~acc_reset. This
        // may be a dynamic signal (ACCRSTN is a real V4 port). load_acc is NOT
        // mapped here: DSP-V4 has no dynamic accumulate-load control, so load_acc
        // must be constant on an accumulate mode -- a non-constant load_acc
        // hard-errors in execute() (require_const_load_acc).
        SigSpec acc_rst = src->hasPort(ID(acc_reset)) ? src->getPort(ID(acc_reset)) : SigSpec(State::S0);
        dsp->setPort(ID(ACCRSTN), invert(module, acc_rst));
        dsp->setPort(ID(ARSTN), one); // async reset inactive (active-low)
        // Clock-enables tied active (Phase 1 does not model per-stage CE gating).
        dsp->setPort(ID(CEA), one);
        dsp->setPort(ID(CEB), one);
        dsp->setPort(ID(CEC), one);
        dsp->setPort(ID(CED), one);
        dsp->setPort(ID(CEP), one);
    }

    // Build the QL_DSP4 data ports shared by every mapping. `z_out` is the V2 z
    // net (becomes P).
    void connect_common_data(RTLIL::Cell *dsp, RTLIL::Cell *src)
    {
        SigSpec a = src->hasPort(ID(a)) ? src->getPort(ID(a)) : SigSpec();
        SigSpec b = src->hasPort(ID(b)) ? src->getPort(ID(b)) : SigSpec();
        SigSpec z = src->hasPort(ID(z)) ? src->getPort(ID(z)) : SigSpec();
        a.extend_u0(32);
        b.extend_u0(18);
        z.extend_u0(50);
        dsp->setPort(ID(A), a);
        dsp->setPort(ID(B), b);
        dsp->setPort(ID(P), z);
    }

    // Wire the V2 cascade output (z_cout) to the V4 dedicated cascade output PCOUT,
    // so a downstream DSP whose z_cin (=> PCIN) reads this net gets driven
    // (P1-FR-4). In dspv2_sim.v z_cout_o == z_o, and in dspv4_sim.v P == PCOUT, so
    // PCOUT carries the same accumulated value. Skip when z_cout is unconnected, or
    // when it is the same net as z (P) -- driving one net from both P and PCOUT
    // would create two drivers on that net.
    void connect_pcout(RTLIL::Cell *dsp, RTLIL::Cell *src)
    {
        if (!src->hasPort(ID(z_cout)))
            return;
        SigSpec zc = src->getPort(ID(z_cout));
        SigSpec zo = src->hasPort(ID(z)) ? src->getPort(ID(z)) : SigSpec();
        if (GetSize(zc) > 0 && zc != zo)
            dsp->setPort(ID(PCOUT), zc);
    }

    // Emit config word for a per-cell (non-fused) conversion. Returns false if
    // the mode is out of Phase-1 scope (caller hard-errors).
    void emit_per_cell(RTLIL::Module *module, RTLIL::Cell *src, V2Mode mode, const V2Config &c)
    {
        RTLIL::Cell *dsp = module->addCell(module->uniquify(RTLIL::escape_id(src->name.str() + "_DSP4")), ID(QL_DSP4));

        connect_common_data(dsp, src);
        connect_clocking(module, dsp, src);

        // Pre-adder operand: V2 c -> V4 D (pre-adder modes only). Otherwise D is
        // unused (INMODE[2]=0 gates it off) -> left untied.
        if (mode == V2Mode::PREADDER_MULT || mode == V2Mode::PREADDER_MULTADD) {
            SigSpec d = src->hasPort(ID(c)) ? src->getPort(ID(c)) : SigSpec();
            d.extend_u0(27);
            dsp->setPort(ID(D), d);
        }

        // Genuine z->PCIN cascade for MULTADD/PREADDER_MULTADD (P1-FR-4). Otherwise
        // the OPMODE Z field does not select PCIN, so PCIN is unused -> left untied.
        bool z_cascade = (mode == V2Mode::MULTADD || mode == V2Mode::MULTADD_NEG || mode == V2Mode::PREADDER_MULTADD);
        if (z_cascade && src->hasPort(ID(z_cin))) {
            SigSpec zc = src->getPort(ID(z_cin));
            zc.extend_u0(50);
            dsp->setPort(ID(PCIN), zc);
        }
        // CIN is an active ALU carry-in (selected by CARRYINSEL=000 and summed in
        // the ALU), so it is driven to 0. All genuinely-unused inputs -- C (per-cell
        // never selects it), ACIN/BCIN (A/B cascade), CCIN, SIGNCIN -- are left
        // untied.
        dsp->setPort(ID(CIN), State::S0);

        // Drive the dedicated cascade output: V2 z_cout -> V4 PCOUT, so a downstream
        // DSP reading this net on z_cin (=> PCIN) sees the cascade value (P1-FR-4;
        // dspv2_sim.v z_cout_o == z_o). Skip if z_cout is unconnected or is the same
        // net as z (P) to avoid double-driving one net from both P and PCOUT.
        connect_pcout(dsp, src);

        // ---- config word (Appendix A, per-cell rows) ----
        uint32_t opmode = 0, alumode = 0, inmode = 0;
        bool amultsel = false, bmultsel = false, preaddinsel = false;
        bool accumulate = false;

        switch (mode) {
        case V2Mode::MULT:
            opmode = 0b000000101;
            break;
        case V2Mode::MULTACC:
            opmode = 0b000100101;
            accumulate = true;
            break;
        case V2Mode::MULTACC_NEG:
            opmode = 0b000100101;
            alumode = 0b11;
            accumulate = true;
            break;
        case V2Mode::MULTADD:
            opmode = 0b000010101; // Z = PCIN
            break;
        case V2Mode::MULTADD_NEG:
            opmode = 0b000010101;
            alumode = 0b11;
            break;
        case V2Mode::PREADDER_MULT:
            opmode = 0b000000101;
            inmode = c.subtract ? 0b01100 : 0b00100; // INMODE[3]=pre-adder sub
            bmultsel = true;                          // BMULTSEL = AD
            preaddinsel = true;                       // PREADDINSEL = B path
            break;
        case V2Mode::PREADDER_MULTADD:
            opmode = 0b000010101; // Z = PCIN
            inmode = c.subtract ? 0b01100 : 0b00100;
            bmultsel = true;
            preaddinsel = true;
            break;
        default:
            log_error("ql_dspv2_to_dspv4: cell %s has mode %s which is out of Phase-1 scope (P1-FR-6).\n", log_id(src->name), mode_name(mode));
            return;
        }

        dsp->setParam(ID(OPMODE), c9(opmode));
        dsp->setParam(ID(ALUMODE), c2(alumode));
        dsp->setParam(ID(INMODE), c5(inmode));
        dsp->setParam(ID(CARRYINSEL), c3(0));
        dsp->setParam(ID(USE_SIMD), c2(0));
        dsp->setParam(ID(AMULTSEL), c1(amultsel));
        dsp->setParam(ID(BMULTSEL), c1(bmultsel));
        dsp->setParam(ID(PREADDINSEL), c1(preaddinsel));
        set_reg_params(dsp, c, accumulate, /*creg=*/0);
        set_rss_params(dsp, c);

        // load_acc gates the accumulator update (1=accumulate, 0=hold), i.e. it is
        // the enable of the V4 P/accumulator register -> CEP. It is guaranteed
        // constant for accumulate modes (a variable load_acc hard-errors in
        // execute(), require_const_load_acc), so this is a STATIC tie: CEP=1 =>
        // accumulate every cycle, CEP=0 => hold. (connect_clocking left CEP=1.)
        if (accumulate)
            dsp->setPort(ID(CEP), src->hasPort(ID(load_acc)) ? src->getPort(ID(load_acc)) : SigSpec(State::S1));

        // Accumulate mode that also has the V2 output register: PREG holds the
        // accumulator, so add an external dffre on P for the extra output stage.
        if (accumulate && c.out_reg)
            add_output_dffre(module, dsp, src);

        log("  %s: %s -> QL_DSP4 %s (OPMODE=%s ALUMODE=%s INMODE=%s%s)\n", log_id(src->name), mode_name(mode),
            log_id(dsp->name), c9(opmode).as_string().c_str(), c2(alumode).as_string().c_str(), c5(inmode).as_string().c_str(),
            (accumulate && c.out_reg) ? " +out_dffre" : "");

        // NOTE: src is NOT removed here -- removal is deferred to the end of
        // execute() so no RTLIL::Cell is freed while the v2cells/cfg/mode pointers
        // are still live (a mid-loop remove + addCell can reuse the freed address
        // and cause the pass to reprocess its own output -> corruption/crash).
    }

    // ---- fusion (P1-FR-3, Appendix B) --------------------------------------

    // Addend delay reproducible only for k <= 1 (V4 C path has CREG only).
    // k = concat input reg + concat output reg + consumer z_cin reg (Appendix B).
    //
    // concat_in  (CONCAT_CASCADE_REGIN)  <- concat A/B input registers.
    // concat_out (CONCAT_CASCADE_REGOUT) <- concat M/output register.
    // cons_zcin  <- the consumer's separate z_cin-path register. NOTE: MODE_BITS
    //   bit 71 (ZCIN_REG) is consumed as the z_cin *select* (it must be 1 for a
    //   cell to classify as MULTADD), so it cannot also encode this independent
    //   delay. Phase 1 has no other verified MODE_BITS bit for a z_cin pipeline
    //   register, so it is treated as 0 here (the common case). The k>=2
    //   hard-error remains the safety net for deep concat pipelines.
    int fusion_k(const V2Config &concat, const V2Config &consumer, int &concat_in, int &concat_out, int &cons_zcin)
    {
        (void)consumer;
        // Concat input-register stages delay the A1:B1 addend. Use the SAME stage
        // decode as the datapath register mapping (a_stages/b_stages cover A_REG,
        // A1_REG&A2_REG and A2_REG-alone, plus the B-side equivalents), so an input
        // register carried by any of those encodings is counted -- not just the
        // single A_REG/B_REG bits. A1 and B1 must be delay-aligned, so take the
        // larger of the two. Over-counting here turns into a k>=2 hard-error, which
        // is the safe direction (never a silent latency miscompile).
        int ci = a_stages(concat);
        int cbi = b_stages(concat);
        concat_in = (cbi > ci) ? cbi : ci;
        // Concat output-register stage = the output register (output_select[2],
        // i.e. out_reg). Confirmed against dspv2_sim.v: output_select>=4 selects the
        // registered z1 (a single flop) onto z_cout (z1 <= z2 :1544, z_o/z_cout_o
        // mux :1548-1557); output_select<4 drives z_cout combinationally. M_REG is
        // deliberately NOT counted: for a CONCAT (feedback==2) add_a={a,b} bypasses
        // the multiplier M register (:1425), so M_REG cannot delay the A:B addend.
        concat_out = concat.out_reg ? 1 : 0;
        // No verified MODE_BITS bit encodes an independent consumer z_cin pipeline
        // register in Phase 1 (bit 71 is the z_cin *select*, required for MULTADD
        // classification), so treat it as 0; the k>=2 hard-error is the safety net.
        cons_zcin = 0;
        return concat_in + concat_out + cons_zcin;
    }

    void emit_fused(RTLIL::Module *module, RTLIL::Cell *concat, RTLIL::Cell *consumer, V2Mode consumer_mode, const V2Config &cc,
                    const V2Config &dc)
    {
        int k_in, k_out, k_zcin;
        int k = fusion_k(cc, dc, k_in, k_out, k_zcin);
        if (k >= 2) {
            log_error("ql_dspv2_to_dspv4: cannot fuse CONCAT_CASCADE %s + %s %s: addend latency k=%d "
                      "(concat_in=%d concat_out=%d consumer_zcin=%d). The V4 C path has a single "
                      "register (CREG); only k<=1 is reproducible without external balancing "
                      "flops (Phase-1 limitation, P1-FR-12 / MM-7). Fully-pipelined CONCAT chains "
                      "are deferred to a later phase.\n",
                      log_id(concat->name), mode_name(consumer_mode), log_id(consumer->name), k, k_in, k_out, k_zcin);
            return;
        }

        RTLIL::Cell *dsp = module->addCell(module->uniquify(RTLIL::escape_id(consumer->name.str() + "_DSP4F")), ID(QL_DSP4));

        connect_common_data(dsp, consumer);
        connect_clocking(module, dsp, consumer);
        // The fused cell's own cascade output (consumer z_cout) may feed a further
        // downstream stage -> drive PCOUT (P1-FR-4).
        connect_pcout(dsp, consumer);

        // Concatenated addend A1:B1 -> V4 C = {A1[31:0], B1[17:0]} (confirmed).
        SigSpec a1 = concat->hasPort(ID(a)) ? concat->getPort(ID(a)) : SigSpec();
        SigSpec b1 = concat->hasPort(ID(b)) ? concat->getPort(ID(b)) : SigSpec();
        a1.extend_u0(32);
        b1.extend_u0(18);
        SigSpec c_sig;
        c_sig.append(b1); // C[17:0]  = B1
        c_sig.append(a1); // C[49:18] = A1
        dsp->setPort(ID(C), c_sig);

        // Pre-adder operand for the fused PREADDER_MULTADD case (else D unused -> untied).
        if (consumer_mode == V2Mode::PREADDER_MULTADD) {
            SigSpec d = consumer->hasPort(ID(c)) ? consumer->getPort(ID(c)) : SigSpec();
            d.extend_u0(27);
            dsp->setPort(ID(D), d);
        }

        // The fused addend travels via C (set above); PCIN is unused here -> untied.
        // CIN is an active ALU carry-in (CARRYINSEL=000) -> driven to 0. ACIN/BCIN
        // (A/B cascade), CCIN and SIGNCIN are unused -> left untied.
        dsp->setPort(ID(CIN), State::S0);

        // Config word (Appendix A, fused rows). OPMODE Z field selects C.
        uint32_t opmode = 0b000110101;
        uint32_t alumode = 0, inmode = 0;
        bool bmultsel = false, preaddinsel = false;
        if (consumer_mode == V2Mode::MULTADD_NEG)
            alumode = 0b11;
        if (consumer_mode == V2Mode::PREADDER_MULTADD) {
            inmode = dc.subtract ? 0b01100 : 0b00100;
            bmultsel = true;
            preaddinsel = true;
        }
        dsp->setParam(ID(OPMODE), c9(opmode));
        dsp->setParam(ID(ALUMODE), c2(alumode));
        dsp->setParam(ID(INMODE), c5(inmode));
        dsp->setParam(ID(CARRYINSEL), c3(0));
        dsp->setParam(ID(USE_SIMD), c2(0));
        dsp->setParam(ID(AMULTSEL), c1(false));
        dsp->setParam(ID(BMULTSEL), c1(bmultsel));
        dsp->setParam(ID(PREADDINSEL), c1(preaddinsel));
        set_reg_params(dsp, dc, /*accumulate=*/false, /*creg=*/k);
        set_rss_params(dsp, dc);

        log("  fused CONCAT_CASCADE %s + %s %s -> QL_DSP4 %s (C={A1,B1}, k=%d, CREG=%d)\n", log_id(concat->name),
            mode_name(consumer_mode), log_id(consumer->name), log_id(dsp->name), k, k);

        // Removal deferred (see emit_per_cell note) -- concat/consumer are removed
        // at the end of execute() to avoid freeing cells while pointers are live.
    }

    // ---- cascade-fanout legalization (Bucket D fix, approach (a)) ----------

    // Enforce the dedicated-cascade fanout-1 invariant. Synplify keeps each
    // accumulate chain's cascade seed private (every z_cout drives exactly one
    // z_cin); a value shared across chains (e.g. a common a*b product Synplify
    // computes once and routes to several chains) is legal there because the
    // sharing is on GENERAL ROUTING, upstream of each chain's own private cascade
    // injector. Our per-cell mapping instead binds that shared feeder straight onto
    // PCIN, which the dsp4_logical tile realizes on the dedicated pcin_i cascade --
    // turning a legal shared bus into an illegal fanout>1 cascade net that VPR
    // cannot place ("appears in 2 placement macros").
    //
    // Only the PCIN (Z=001) addend is affected; the fused Z=C addend rides general
    // routing and is exempt (see cascade_addend_port).
    //
    // Restore Synplify's structure -- one private, single-fanout cascade head per
    // chain -- by replicating the feeder DSP once per extra consumer. The replica
    // shares the feeder's inputs (fanout on general routing is fine) and drives a
    // fresh, private output into just one consumer, so every cascade-addend net
    // ends up point-to-point. This only fires when a feeder is genuinely shared
    // across cascade chains (the `wrap`+`shared`+`cascade` case); ordinary cascade
    // chains have a distinct driver per stage and are left untouched.
    void legalize_cascade_fanout(RTLIL::Module *module)
    {
        SigMap sigmap(module);

        // Driver map: each QL_DSP4 output bit -> the cell that drives it.
        dict<SigBit, RTLIL::Cell *> driver_of;
        for (RTLIL::Cell *cell : module->cells()) {
            if (cell->type != ID(QL_DSP4))
                continue;
            for (auto &conn : cell->connections()) {
                if (!dsp4_output_ports().count(conn.first))
                    continue;
                for (SigBit b : sigmap(conn.second))
                    if (b.wire != nullptr)
                        driver_of[b] = cell;
            }
        }

        // Group cascade consumers by the single cell that drives their addend net.
        // A normal cascade chain has a distinct driver per stage (fanout 1) and so
        // never groups; only a shared feeder collects more than one consumer.
        dict<RTLIL::Cell *, std::vector<std::pair<RTLIL::Cell *, RTLIL::IdString>>> consumers_of;
        for (RTLIL::Cell *cell : module->cells()) {
            RTLIL::IdString port = cascade_addend_port(cell);
            if (port.empty() || !cell->hasPort(port))
                continue;
            RTLIL::Cell *drv = nullptr;
            bool single_driver = true;
            for (SigBit b : sigmap(cell->getPort(port))) {
                if (b.wire == nullptr)
                    continue;
                auto it = driver_of.find(b);
                RTLIL::Cell *d = (it != driver_of.end()) ? it->second : nullptr;
                if (d == nullptr)
                    continue;
                if (drv == nullptr)
                    drv = d;
                else if (drv != d)
                    single_driver = false;
            }
            if (drv != nullptr && single_driver)
                consumers_of[drv].push_back(std::make_pair(cell, port));
        }

        int replicas = 0;
        for (auto &grp : consumers_of) {
            RTLIL::Cell *feeder = grp.first;
            std::vector<std::pair<RTLIL::Cell *, RTLIL::IdString>> &cons = grp.second;
            if (GetSize(cons) <= 1)
                continue;
            // Leave the first consumer on the original feeder; give each of the rest
            // its own private copy so its cascade-addend net becomes fanout 1.
            for (int i = 1; i < GetSize(cons); i++) {
                RTLIL::Cell *consumer = cons[i].first;
                RTLIL::IdString port = cons[i].second;

                RTLIL::Cell *clone = module->addCell(module->uniquify(RTLIL::escape_id(feeder->name.str() + "_casc_dup")), feeder->type);
                clone->parameters = feeder->parameters;
                clone->attributes = feeder->attributes;

                // Copy inputs verbatim (shared fabric routing); give every output a
                // fresh wire and record old-bit -> new-bit so we can repoint just
                // this consumer's addend (handles the sign-extend / reorder that
                // emit_fused / emit_per_cell apply to the addend spec).
                dict<SigBit, SigBit> sub;
                for (auto &conn : feeder->connections()) {
                    if (dsp4_output_ports().count(conn.first)) {
                        RTLIL::Wire *w = module->addWire(NEW_ID, GetSize(conn.second));
                        clone->setPort(conn.first, w);
                        SigSpec oldbits = sigmap(conn.second);
                        SigSpec newbits(w);
                        for (int j = 0; j < GetSize(oldbits); j++)
                            if (oldbits[j].wire != nullptr)
                                sub[oldbits[j]] = newbits[j];
                    } else {
                        clone->setPort(conn.first, conn.second);
                    }
                }

                SigSpec addend = consumer->getPort(port);
                SigSpec repointed;
                for (SigBit b : addend) {
                    SigBit sb = sigmap(b);
                    repointed.append(sub.count(sb) ? sub.at(sb) : b);
                }
                consumer->setPort(port, repointed);
                replicas++;
                log("  cascade legalize: replicated feeder %s -> %s for %s.%s (private "
                    "single-fanout cascade head)\n",
                    log_id(feeder->name), log_id(clone->name), log_id(consumer->name), log_id(port));
            }
        }
        if (replicas)
            log("  cascade legalize: added %d feeder replica(s) to keep every dedicated "
                "cascade net fanout-1.\n",
                replicas);

        // Safety net: assert the invariant. A residual shared cascade addend whose
        // feeder we could not replicate (e.g. not driven by a QL_DSP4) is a hard
        // error here -- caught in synthesis rather than as an opaque VPR placement
        // abort much later in the flow.
        dict<SigBit, RTLIL::Cell *> casc_sink;
        for (RTLIL::Cell *cell : module->cells()) {
            RTLIL::IdString port = cascade_addend_port(cell);
            if (port.empty() || !cell->hasPort(port))
                continue;
            for (SigBit b : sigmap(cell->getPort(port))) {
                if (b.wire == nullptr)
                    continue;
                auto it = casc_sink.find(b);
                if (it != casc_sink.end() && it->second != cell)
                    log_error("ql_dspv2_to_dspv4: dedicated DSP cascade net %s feeds the cascade "
                              "addend of both %s and %s (fanout > 1). A physical DSP cascade wire "
                              "is point-to-point and cannot be placed; the shared feeder could not "
                              "be privately replicated (Bucket D invariant).\n",
                              log_signal(b), log_id(it->second->name), log_id(cell->name));
                casc_sink[b] = cell;
            }
        }
    }

    // ---- driver ------------------------------------------------------------

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        log_header(design, "Executing QL_DSPV2_TO_DSPV4 pass (DSP-V2 -> DSP-V4, Phase 1).\n");
        extra_args(args, 1, design);

        for (RTLIL::Module *module : design->selected_modules()) {
            SigMap sigmap(module);
            dict<SigBit, State> const_drivers;
            build_const_drivers(module, sigmap, const_drivers);

            // Snapshot the QL_DSPV2 cells (we mutate the module while iterating).
            std::vector<RTLIL::Cell *> v2cells;
            for (RTLIL::Cell *cell : module->selected_cells())
                if (cell->type == ID(QL_DSPV2))
                    v2cells.push_back(cell);

            // Decode + classify every cell up front.
            dict<RTLIL::Cell *, V2Config> cfg;
            dict<RTLIL::Cell *, V2Mode> mode;
            for (RTLIL::Cell *cell : v2cells) {
                if (!cell->hasParam(ID(MODE_BITS))) {
                    log_error("ql_dspv2_to_dspv4: cell %s (QL_DSPV2) has no MODE_BITS parameter.\n", log_id(cell->name));
                    continue;
                }
                V2Config c = decode_mode_bits(cell);
                check_v2_only_config(cell, c);
                int fb = get_const_port(cell, ID(feedback), sigmap, const_drivers);
                int os = get_const_port(cell, ID(output_select), sigmap, const_drivers);
                c.out_reg = (os >= 4); // output_select[2] = output register
                V2Mode m = classify(control_word(fb, os, c));
                // Accumulate modes rely on load_acc; V4 has no dynamic equivalent,
                // so it must be constant (CASE 2/3).
                if (m == V2Mode::MULTACC || m == V2Mode::MULTACC_NEG)
                    require_const_load_acc(cell, sigmap, const_drivers);
                cfg[cell] = c;
                mode[cell] = m;
            }

            // Map each CONCAT_CASCADE z_cout net -> the concat cell, for fusion.
            dict<SigBit, RTLIL::Cell *> concat_by_zcout;
            for (RTLIL::Cell *cell : v2cells) {
                if (mode[cell] != V2Mode::CONCAT_CASCADE)
                    continue;
                if (!cell->hasPort(ID(z_cout)))
                    continue;
                SigSpec zc = sigmap(cell->getPort(ID(z_cout)));
                for (int i = 0; i < GetSize(zc); i++)
                    if (zc[i].wire != nullptr)
                        concat_by_zcout[zc[i]] = cell;
            }

            // Pass 1: fuse CONCAT_CASCADE + downstream MULTADD/PREADDER_MULTADD.
            pool<RTLIL::Cell *> consumed;
            for (RTLIL::Cell *cell : v2cells) {
                V2Mode m = mode[cell];
                bool fusible_consumer = (m == V2Mode::MULTADD || m == V2Mode::MULTADD_NEG || m == V2Mode::PREADDER_MULTADD);
                if (!fusible_consumer || !cell->hasPort(ID(z_cin)))
                    continue;
                SigSpec zin = sigmap(cell->getPort(ID(z_cin)));
                RTLIL::Cell *concat = nullptr;
                for (int i = 0; i < GetSize(zin); i++) {
                    if (zin[i].wire == nullptr)
                        continue;
                    auto it = concat_by_zcout.find(zin[i]);
                    if (it != concat_by_zcout.end()) {
                        concat = it->second;
                        break;
                    }
                }
                if (concat == nullptr || consumed.count(concat) || consumed.count(cell))
                    continue;
                emit_fused(module, concat, cell, m, cfg[concat], cfg[cell]);
                consumed.insert(concat);
                consumed.insert(cell);
            }

            // Pass 2: per-cell conversion for everything not fused.
            for (RTLIL::Cell *cell : v2cells) {
                if (consumed.count(cell))
                    continue;
                V2Mode m = mode[cell];
                if (m == V2Mode::CONCAT_CASCADE) {
                    log_error("ql_dspv2_to_dspv4: cell %s is a CONCAT_CASCADE with no fusible consumer "
                              "(its z_cout does not drive a MULTADD/PREADDER_MULTADD z_cin). "
                              "CONCAT_CASCADE is only supported as part of a fused pair in "
                              "Phase 1 (D6/D7, P1-FR-6).\n",
                              log_id(cell->name));
                    continue;
                }
                if (m == V2Mode::UNKNOWN) {
                    log_error("ql_dspv2_to_dspv4: cell %s has an unrecognized / out-of-scope QL_DSPV2 mode "
                              "(control word not in the Phase-1 set). Unmappable cells hard-error "
                              "(D11, P1-FR-6).\n",
                              log_id(cell->name));
                    continue;
                }
                emit_per_cell(module, cell, m, cfg[cell]);
            }

            // Deferred removal: now that all conversions are done and no more
            // pointers into v2cells are dereferenced, remove the original QL_DSPV2
            // cells. Removing them earlier (inside emit_*) frees RTLIL::Cell objects
            // whose addresses Yosys then reuses for the newly-added QL_DSP4/$not
            // cells, which would make a later loop iteration dereference a stale
            // pointer and reprocess the pass's own output (corruption / crash).
            for (RTLIL::Cell *cell : v2cells)
                module->remove(cell);

            // Every QL_DSPV2 cell is now a QL_DSP4. Enforce the dedicated-cascade
            // fanout-1 invariant on the emitted netlist: replicate any feeder that
            // a shared value drove onto more than one chain's cascade addend, so no
            // physical cascade wire fans out (Bucket D).
            legalize_cascade_fanout(module);
        }
    }
} QlDspV2ToV4Pass;

PRIVATE_NAMESPACE_END
