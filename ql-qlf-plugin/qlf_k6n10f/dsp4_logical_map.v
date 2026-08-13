// Copyright 2020-2026 F4PGA Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0
//
// DSP-V4 synthesis Phase 2 - techmap that decomposes the monolithic `QL_DSP4`
// base cell (Phase-1 output) into the `dsp4_logical` operating-mode leaf cells
// (QL_DSP4_MULT / QL_DSP4_ALU_* / QL_DSP4_PREADD|PRESUB / QL_DSP4_RSS and the
// bit-sliced pipeline registers). Run as `techmap -map dsp4_logical_map.v`
// after `ql_dspv2_to_dspv4`. The leaf black boxes are provided by
// `QL_DSP4_leaves.v` (read `-lib` in `begin`).
//
// The `dsp4_logical` mode's internal muxes / sign-extend fanouts / node wires
// are *fabric routing*, not cells: this map only instantiates the leaves and
// connects them leaf-to-leaf + to the QL_DSP4 data ports. VPR pack+route then
// realizes each mux as the single fanin we present. Unused ALU operands are
// left *unconnected* (there is no constant-zero mux input in the mode; an open
// primitive input packs as 0).
//
// Scope: the full W/X/Y/Z operand-mux decode of OPMODE, so every mode whose
// operands come from {0, U, V, P, C, A:B, PCIN} is lowered correctly. Still
// unimplemented (and REJECTED via _TECHMAP_FAIL_ rather than silently mapped
// wrong): USE_SIMD segmentation, CARRYINSEL/CIN, the Z >>17 and MACC_EXT
// sources, ACIN/BCIN inputs, and the AMULTSEL/BMULTSEL/PREADDINSEL multiplier
// routing beyond the pre-adder-on-B shape. See DSPV4_SYNTHESIS_REQUIREMENTS_AND_PLAN.md
// (TM-1..TM-9) in aurora2.
//
// A rejected cell stays un-lowered and fails later with "no such model", which
// is noisy but safe. It must never map silently: an open ALU operand packs as
// 0, so a dropped operand yields a working-but-wrong netlist that no stage of
// the flow flags.
//
// INMODE[0] / INMODE[4] -- why they are rejected even though they are NOT mode
// bits.  They are register-path selects (reg_path.v REG_PATH_SEL: [0] on the A
// path, [4] on the B path).  They do not change which operation the DSP
// performs -- no entry in the mode table sets either -- but cascade-path
// operations do set them, and they DO change operand pipeline depth:
//
//   PATH_OUT = a_r2_sel                            -> the A:B concat (X mux)
//   GATE_OUT = REG_PATH_SEL ? a_r1 : a_r2_sel      -> multiplier / pre-adder
//
// This map builds ONE tap per operand (a_path / b_path) and uses it for both,
// which is correct only while these bits are 0.  Supporting them means building
// the second tap: route a_r1 to the multiplier while a_path keeps feeding A:B.
// Note a_r1 is the FIRST flop bank's output, which exists in hardware
// regardless of REG0 (the RTL bypasses it with a mux), so INMODE[0]=1 requires
// instantiating QL_DSP4_A1_DFFRE even when AREG0=0.  Same for B / INMODE[4].
//
// Until that lands, rejecting is mandatory: silently ignoring these bits would
// give the wrong operand pipeline depth with nothing to catch it.  See CR-6 and
// TM-5a in aurora2 DSPV4_SYNTHESIS_REQUIREMENTS_AND_PLAN.md.
//
// Sources of truth: function = behavioral_model/dspv4_sim.v; exact leaf
// interface + wiring = FPGA0806 vpr-rendered.xml `<mode name="dsp4_logical">`.

module QL_DSP4 #(
    parameter [8:0] OPMODE      = 9'b000000101,  // W[8:7] Z[6:4] Y[3:2] X[1:0]
    parameter [1:0] ALUMODE     = 2'b00,         // 00 add, 11 sub, 01 rsub, 10 not
    parameter [4:0] INMODE      = 5'b00000,      // [0]=A reg-path sel, [1]=A/B
                                                 // zero-gate, [2]=D-active gate,
                                                 // [3]=pre-adder sub, [4]=B reg-path sel
    parameter [2:0] CARRYINSEL  = 3'b000,
    parameter [1:0] USE_SIMD    = 2'b00,
    parameter       AREG0       = 1'b0,          // A reg stage 0 (first)
    parameter       AREG1       = 1'b0,          // A reg stage 1 (single-stage uses this)
    parameter       BREG0       = 1'b0,
    parameter       BREG1       = 1'b0,
    parameter       A_COUT_SEL  = 1'b0,
    parameter       B_COUT_SEL  = 1'b0,
    parameter       CREG        = 1'b0,
    parameter       DREG        = 1'b0,
    parameter       ADREG       = 1'b0,
    parameter       MREG        = 1'b0,
    parameter       PREG        = 1'b0,
    parameter       COUTREG     = 1'b0,
    parameter       A_IN_SEL    = 1'b0,
    parameter       B_IN_SEL    = 1'b0,
    parameter       AMULTSEL     = 1'b0,
    parameter       BMULTSEL     = 1'b0,
    parameter       PREADDINSEL  = 1'b0,
    parameter       USE_RSS      = 1'b0,
    parameter [2:0] ROUND        = 3'b000,
    parameter [5:0] SHIFT        = 6'b000000,
    parameter       SATURATE     = 1'b0
) (
    // Data inputs
    input  wire [31:0] A,
    input  wire [17:0] B,
    input  wire [49:0] C,
    input  wire [26:0] D,
    input  wire        CIN,
    // Cascade inputs
    input  wire [31:0] ACIN,
    input  wire [17:0] BCIN,
    input  wire [49:0] PCIN,
    input  wire        CCIN,
    input  wire        SIGNCIN,
    // Outputs
    output wire [49:0] P,
    output wire [31:0] ACOUT,
    output wire [17:0] BCOUT,
    output wire [49:0] PCOUT,
    output wire        CCOUT,
    output wire        SIGNCOUT,
    output wire [3:0]  COUT,
    // Clocking / reset / clock-enables
    (* clkbuf_sink *)
    input  wire        CLK,
    input  wire        CEA,
    input  wire        CEB,
    input  wire        CEC,
    input  wire        CED,
    input  wire        CEP,
    input  wire        ARSTN,   // async, active-low  -> leaf R
    input  wire        RSTN,    // sync  (not modeled in the operating mode)
    input  wire        ACCRSTN  // sync  (not modeled in the operating mode)
);

    // -- mode decode (constants) --
    localparam USE_PREADD = INMODE[2];             // pre-adder active (D-active gate)
    localparam PREADD_SUB = INMODE[3];             // pre-adder subtract

    // OPMODE operand-mux fields (dsp4_top.v :242-315 is authoritative).
    //   W = OPMODE[8:7] : 00 = 0, 01 = P, 10 = UNUSED, 11 = C
    //   Z = OPMODE[6:4] : 000 = 0, 001 = PCIN, 010 = P, 011 = C,
    //                     100 = MACC_EXT, 101 = PCIN>>17, 110 = P>>17
    //   Y = OPMODE[3:2] : 00 = 0, 01 = V, 10 = UNUSED (zero, NOT all-ones --
    //                     the requirements doc IR-6 is wrong here), 11 = C
    //   X = OPMODE[1:0] : 00 = 0, 01 = U, 10 = P, 11 = A:B
    localparam [1:0] W_SEL = OPMODE[8:7];
    localparam [2:0] Z_SEL = OPMODE[6:4];
    localparam [1:0] Y_SEL = OPMODE[3:2];
    localparam [1:0] X_SEL = OPMODE[1:0];

    // "Connected" = this operand drives a leaf input. Everything else is left
    // open, which packs as 0.
    localparam W_CONN = (W_SEL == 2'b01) || (W_SEL == 2'b11);
    localparam X_CONN = (X_SEL != 2'b00);
    localparam Y_CONN = (Y_SEL == 2'b01) || (Y_SEL == 2'b11);
    localparam Z_CONN = (Z_SEL == 3'b001) || (Z_SEL == 3'b010) || (Z_SEL == 3'b011);
    localparam Z_ACC  = (Z_SEL == 3'b010);         // kept: used by the ACC block

    // Any operand taking the P feedback node. dsp4_top.v:390 has
    // `p_acc = PREG ? p_reg : alu_result`, so selecting P without a P register
    // closes a combinational loop through the ALU -- reject it.
    localparam USES_P = (W_SEL == 2'b01) || (X_SEL == 2'b10) || Z_ACC;

    // -- register-stage folding (M stage -> P stage) --
    // MREG (multiplier-output flops) and PREG (accumulator / output flops) each
    // add one cycle between the multiplier and P. When only ONE of the two is
    // requested, realize that single stage on the ACC/P register and leave the
    // M/MV flops out entirely: same latency, one physical stage, and the ALU
    // sits inside the registered path instead of behind it. The dedicated M
    // stage is instantiated only when BOTH are requested (e.g. V2 m_reg plus an
    // accumulate mode), where two distinct cycles are actually needed.
    localparam USE_MREG = (MREG && PREG);
    localparam USE_PREG = (MREG || PREG);

    // -- configurations this techmap does not implement --------------------
    // Reject rather than mis-map (see the header). Each term is a capability
    // tracked by scripts/dspv4/techmap_coverage.py in aurora2.
    localparam UNSUPPORTED =
           (USE_SIMD    != 2'b00)                       // SIMD segmentation
        || (CARRYINSEL  != 3'b000)                      // carry cascade / CIN
        || (W_SEL == 2'b10)                             // reserved W encoding
        || (Y_SEL == 2'b10)                             // reserved Y encoding
        || (Z_SEL[2] == 1'b1)                           // MACC_EXT, >>17 sources
        || (A_IN_SEL || B_IN_SEL)                       // ACIN / BCIN inputs
        || (INMODE[1])                                  // operand zero-gate
        || (INMODE[0] || INMODE[4])                     // reg-path select, see below
        || (PREADD_SUB && !USE_PREADD)                  // pre-adder w/ D gated off
        || (AMULTSEL)                                   // pre-adder into 32b port
        || (BMULTSEL != PREADDINSEL)                    // unsupported mult routing
        || (BMULTSEL != USE_PREADD)                     // pre-adder select mismatch
        // Combinational P feedback. This tests PREG, *not* USE_PREG: the
        // folding below sets USE_PREG whenever MREG is set, so testing USE_PREG
        // let MREG=1/PREG=0 through the guard. dsp4_top.v then has
        // `p_acc = alu_result` -- a real combinational loop, an illegal cell --
        // while the folded netlist quietly inserted an accumulator register and
        // broke the loop, producing a working-but-different circuit. That
        // silently mis-mapped 11 P-feedback modes (MULT_ACC, ACC_AB, PASS_P,
        // ...) instead of rejecting them.
        || (USES_P && !PREG);                           // combinational P feedback

    wire _TECHMAP_FAIL_ = UNSUPPORTED;

    genvar i;

    // =======================================================================
    // A input path : optional stage-0 (A1, AREG0) then optional stage-1 (A2,
    // AREG1). A single register stage uses A2 (matches the areg0/areg1 bypass
    // muxes in the mode); two stages chain A1 -> A2.
    // =======================================================================
    wire [31:0] a_s0, a_path;
    generate
        if (AREG0) begin : g_a1
            for (i = 0; i < 32; i = i + 1) begin : b
                QL_DSP4_A1_DFFRE ff (.D(A[i]), .E(CEA), .R(ARSTN), .clk(CLK), .Q(a_s0[i]));
            end
        end else begin : g_a1_byp
            assign a_s0 = A;
        end
        if (AREG1) begin : g_a2
            for (i = 0; i < 32; i = i + 1) begin : b
                QL_DSP4_A2_DFFRE ff (.D(a_s0[i]), .E(CEA), .R(ARSTN), .clk(CLK), .Q(a_path[i]));
            end
        end else begin : g_a2_byp
            assign a_path = a_s0;
        end
    endgenerate

    // =======================================================================
    // B input path : optional B1 (BREG0) then optional B2 (BREG1).
    // =======================================================================
    wire [17:0] b_s0, b_path;
    generate
        if (BREG0) begin : g_b1
            for (i = 0; i < 18; i = i + 1) begin : b
                QL_DSP4_B1_DFFRE ff (.D(B[i]), .E(CEB), .R(ARSTN), .clk(CLK), .Q(b_s0[i]));
            end
        end else begin : g_b1_byp
            assign b_s0 = B;
        end
        if (BREG1) begin : g_b2
            for (i = 0; i < 18; i = i + 1) begin : b
                QL_DSP4_B2_DFFRE ff (.D(b_s0[i]), .E(CEB), .R(ARSTN), .clk(CLK), .Q(b_path[i]));
            end
        end else begin : g_b2_byp
            assign b_path = b_s0;
        end
    endgenerate

    // =======================================================================
    // D path (single stage, DREG) and C path (single stage, CREG).
    // =======================================================================
    wire [26:0] d_path;
    wire [49:0] c_path;
    generate
        if (DREG) begin : g_d
            for (i = 0; i < 27; i = i + 1) begin : b
                QL_DSP4_D_DFFRE ff (.D(D[i]), .E(CED), .R(ARSTN), .clk(CLK), .Q(d_path[i]));
            end
        end else begin : g_d_byp
            assign d_path = D;
        end
        if (CREG) begin : g_c
            for (i = 0; i < 50; i = i + 1) begin : b
                QL_DSP4_C_DFFRE ff (.D(C[i]), .E(CEC), .R(ARSTN), .clk(CLK), .Q(c_path[i]));
            end
        end else begin : g_c_byp
            assign c_path = C;
        end
    endgenerate

    // =======================================================================
    // Pre-adder (pre-adder modes only): AD = D +- B, then optional AD register
    // (ADREG). The pre-adder result drives the 18-bit multiplier port; A drives
    // the 32-bit port. Non-pre-adder modes multiply A (32b) * B (18b) directly.
    // =======================================================================
    wire [31:0] ad_raw, ad_path;
    // B sign-extended 18 -> 32 for the pre-adder's 32-bit operand port.
    wire [31:0] preadd_b = {{14{b_path[17]}}, b_path};
    generate
        if (USE_PREADD) begin : g_pa
            if (PREADD_SUB) begin : g_sub
                QL_DSP4_PRESUB u_pa (.I0(d_path), .I1(preadd_b), .AD(ad_raw));
            end else begin : g_add
                QL_DSP4_PREADD u_pa (.I0(d_path), .I1(preadd_b), .AD(ad_raw));
            end
            if (ADREG) begin : g_ad
                for (i = 0; i < 32; i = i + 1) begin : b
                    QL_DSP4_AD_DFFR ff (.D(ad_raw[i]), .R(ARSTN), .clk(CLK), .Q(ad_path[i]));
                end
            end else begin : g_ad_byp
                assign ad_path = ad_raw;
            end
        end else begin : g_pa_none
            assign ad_raw  = 32'b0;
            assign ad_path = 32'b0;
        end
    endgenerate

    // =======================================================================
    // Multiplier. I1 (32b) = A path; I0 (18b) = pre-adder result (pre-adder
    // modes) or B path.
    // =======================================================================
    wire [17:0] mult_i0;
    wire [31:0] mult_i1 = a_path;
    generate
        if (USE_PREADD) begin : g_mi0_ad
            assign mult_i0 = ad_path[17:0];
        end else begin : g_mi0_b
            assign mult_i0 = b_path;
        end
    endgenerate

    // The multiplier emits its result in carry-save form as two 50-bit vectors
    // plus a dropped-carry flag: U + V == I1*I0 + KN*2^50, with U and V read as
    // UNSIGNED. U is NOT the product, so it must not be sign-extended; the ALU
    // resolves the pair as {14{KN}, U} + {14'b0, V} (dsp4_top.v x_mux / y_mux).
    wire [49:0] mult_u, mult_v;
    wire        mult_kn;
    QL_DSP4_MULT u_mult (.I0(mult_i0), .I1(mult_i1), .U(mult_u), .V(mult_v),
                         .KN(mult_kn));

    // =======================================================================
    // Multiplier-output registers (registers both partial products). Only used
    // when MREG and PREG are both set -- a lone MREG folds onto the P register
    // below (see USE_MREG / USE_PREG).
    // =======================================================================
    wire [49:0] msel, vsel;
    wire        knsel;
    generate
        if (USE_MREG) begin : g_m
            for (i = 0; i < 50; i = i + 1) begin : bu
                QL_DSP4_M_DFFR  ff (.D(mult_u[i]), .R(ARSTN), .clk(CLK), .Q(msel[i]));
            end
            for (i = 0; i < 50; i = i + 1) begin : bv
                QL_DSP4_MV_DFFR ff (.D(mult_v[i]), .R(ARSTN), .clk(CLK), .Q(vsel[i]));
            end
            // KN pipelines in lockstep with U/V (dsp4_top.v:255) so the X-mux
            // pad stays aligned with the partial products it extends.
            QL_DSP4_MK_DFFR ffk (.D(mult_kn), .R(ARSTN), .clk(CLK), .Q(knsel));
        end else begin : g_m_byp
            assign msel  = mult_u;
            assign vsel  = mult_v;
            assign knsel = mult_kn;
        end
    endgenerate

    // =======================================================================
    // Accumulator register (PREG, or a folded-in lone MREG). Feeds the P output
    // and, for MULTACC, the ALU Z operand (P feedback). ALU_OUT / acc feedback
    // are declared first.
    // =======================================================================
    wire [63:0] alu_out;
    wire [3:0]  alu_co;
    wire [63:0] acc_q;
    wire [63:0] p_node;
    generate
        if (USE_PREG) begin : g_acc
            for (i = 0; i < 64; i = i + 1) begin : b
                QL_DSP4_ACC_DFFRE ff (.D(alu_out[i]), .E(CEP), .R(ARSTN), .clk(CLK), .Q(acc_q[i]));
            end
            assign p_node = acc_q;
        end else begin : g_acc_byp
            assign acc_q  = 64'b0;   // unused (Z selects ACC.Q only when PREG=1)
            assign p_node = alu_out;
        end
    endgenerate

    // =======================================================================
    // ALU operands. Each is presented as the single fanin of its mode mux, or
    // left open. All sources sign-extend to the 64-bit accumulator width,
    // matching dsp4_top.v :242-315.
    //
    // A:B is the *registered* A and B path outputs (dsp4_top.v uses
    // preadd_xmux / b_xmux, which are the reg_path PATH_OUT taps) -- i.e. the
    // same a_path / b_path this map already built, not the raw A / B ports.
    // =======================================================================
    // U is padded with KN and V is ZERO-extended -- neither is sign-extended.
    // U and V are the multiplier's carry-save pair, not signed values, and
    // U + V == product + KN*2^50; padding U with KN is what cancels that 2^50
    // excess, and V is an unsigned carry vector. Sign-extending both happens to
    // give the right low 50 bits (carries only propagate upward, so P cannot
    // see the difference), which is why this was invisible until the RSS shift
    // brought the upper accumulator bits back down -- see
    // verify_techmap.py --rss.
    wire [63:0] u_ext    = {{14{knsel}}, msel};
    wire [63:0] v_ext    = {{14{1'b0}},  vsel};
    wire [63:0] c_ext    = {{14{c_path[49]}}, c_path};
    wire [63:0] pcin_ext = {{14{PCIN[49]}}, PCIN};
    wire [63:0] ab_ext   = {{14{a_path[31]}}, a_path, b_path};

    wire [63:0] alu_w = (W_SEL == 2'b01) ? acc_q : c_ext;
    wire [63:0] alu_y = (Y_SEL == 2'b01) ? v_ext : c_ext;
    wire [63:0] alu_x = (X_SEL == 2'b01) ? u_ext :
                        (X_SEL == 2'b10) ? acc_q : ab_ext;
    wire [63:0] alu_z = (Z_SEL == 3'b001) ? pcin_ext :
                        (Z_SEL == 3'b010) ? acc_q : c_ext;

    // 4 ALU cell types x 16 operand-presence combinations. An operand that
    // selects 0 is left OPEN: the dsp4_logical mode has no constant-zero mux
    // input, so a tied 64'b0 would have nothing to route from. Generated --
    // see scripts/dspv4/ in aurora2.
    generate
    if (ALUMODE == 2'b00) begin : g_add
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_ADD u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_ADD u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_ADD u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_ADD u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_ADD u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_ADD u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_ADD u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_ADD u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_ADD u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end else if (ALUMODE == 2'b11) begin : g_sub
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_SUB u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_SUB u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_SUB u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_SUB u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_SUB u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_SUB u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_SUB u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_SUB u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_SUB u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end else if (ALUMODE == 2'b01) begin : g_rsub
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_REV_SUB u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end else if (ALUMODE == 2'b10) begin : g_nsum
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_NOT_SUM u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end
    endgenerate

    // =======================================================================
    // Output stage. P = USE_RSS ? RSS(p_node) : p_node[49:0]. PCOUT mirrors P.
    // =======================================================================
    wire [49:0] p_out;
    generate
        if (USE_RSS) begin : g_rss
            // ROUND / SHIFT / SATURATE ride to the leaf as parameters, the way
            // configuration reaches a leaf on this path (precedent:
            // QL_DSPV2_MULT's MODE_BITS). Ports would need routing from a
            // constant source the operating mode has no provision for -- the
            // same reason unused ALU operands are left open rather than tied.
            // They were previously dropped here, which silently turned every
            // rounding/shifting/saturating configuration into a plain
            // truncation.
            QL_DSP4_RSS #(
                .ROUND   (ROUND),
                .SHIFT   (SHIFT),
                .SATURATE(SATURATE)
            ) u_rss (.ACC_IN(p_node), .ACC_OUT(p_out));
        end else begin : g_rss_byp
            assign p_out = p_node[49:0];
        end
    endgenerate
    assign P     = p_out;
    assign PCOUT = p_out;

    // Carry-out (COUTREG optional; Phase-1 leaves it combinational).
    wire [3:0] cout_w;
    generate
        if (COUTREG) begin : g_co
            for (i = 0; i < 4; i = i + 1) begin : b
                QL_DSP4_CO_DFFR ff (.D(alu_co[i]), .R(ARSTN), .clk(CLK), .Q(cout_w[i]));
            end
        end else begin : g_co_byp
            assign cout_w = alu_co;
        end
    endgenerate
    assign COUT  = cout_w;
    // Cascade carry is a TAP of COUT[3], not a separate register: dsp4_top.v
    // has one carry-out bank (COUTREG) serving both COUT and CCOUT.
    assign CCOUT = cout_w[3];
    // Sign cascade is the ACCUMULATOR sign, not the product sign
    // (dsp4_top.v: assign SIGNCOUT = p_acc[MULT_P_WIDTH-1]). This read msel[49]
    // -- the multiplier's partial-product sum -- which is a different signal
    // entirely and wrong in every mode, including the ones with no multiplier.
    // It went unnoticed because the mode testbench compares only P; see
    // verify_techmap.py --check-cascade.
    assign SIGNCOUT = p_node[49];

    // A/B cascade outputs (registered path taps). Unused in Phase-1 designs
    // (dropped by `clean`), driven here to match the operating-mode taps.
    assign ACOUT = a_path;
    assign BCOUT = b_path;

endmodule
