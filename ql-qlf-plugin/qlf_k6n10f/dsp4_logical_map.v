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
// Techmap: decomposes the monolithic QL_DSP4 cell into the `dsp4_logical`
// operating-mode leaf cells. Run as `techmap -map dsp4_logical_map.v`; the leaf
// blackboxes come from QL_DSP4_leaves.v, read with -lib.
//
// The mode's internal muxes and sign-extend fanouts are fabric routing, not
// cells. This map instantiates only the leaves and presents each mux with its
// single fanin; unused ALU operands are left OPEN, because an open primitive
// input packs as 0 and the mode has no constant-zero mux input.
//
// Unsupported configurations are rejected via _TECHMAP_FAIL_, never mapped
// approximately -- an open operand packs as 0, so a dropped operand yields a
// working-but-wrong netlist that no stage of the flow flags.
//
// Function is defined by behavioral_model/dspv4_sim.v; the leaf interface and
// wiring by the vpr-rendered <mode name="dsp4_logical">.
//
// Rationale, defect history and the INMODE[0]/[4] rejection are in aurora2
// docs/development/DSPV2-to-DSPV4-Synthesis/DSPV4_CODE_CHANGES_PHASE1_3.md.

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
    // The leaf R pin is the SYNCHRONOUS reset. In the operating mode the arch
    // feeds it from rstn_i (tile IC0[3]) for every bank except the accumulator,
    // which is on accrstn_i (IC0[4]) -- both reachable from general routing.
    // ARSTN is the chip-wide async reset: is_non_clock_global with Fc = 0, so no
    // fabric net can drive it and the operating mode does not expose it at all.
    // Wiring a leaf R to ARSTN here would silently put an async reset onto a
    // synchronous pin.
    input  wire        ARSTN,   // async, active-low  -- global only, unused here
    input  wire        RSTN,    // sync, active-low   -> leaf R (all but ACC)
    input  wire        ACCRSTN  // sync, active-low   -> ACC leaf R
);

    // -- mode decode (constants) --
    // INMODE decode. dsp4_top.v is authoritative; the names matter because the
    // obvious reading of INMODE[2] is wrong:
    //   [1] operand zero-gate -- gates A when PREADDINSEL=0, B when it is 1
    //   [2] D-operand gate    -- NOT a pre-adder enable. The pre-adder is always
    //                            in the datapath; [2] only decides whether D or
    //                            zero is its I0. INMODE[3] with [2] low is a
    //                            legal negate: AD = sat(0 - operand).
    //   [3] pre-adder subtract
    localparam D_ACTIVE   = INMODE[2];
    localparam PREADD_SUB = INMODE[3];
    localparam GATE_A     = (!PREADDINSEL) && INMODE[1];
    localparam GATE_B     = ( PREADDINSEL) && INMODE[1];
    // The pre-adder result only needs building when something consumes it.
    localparam USE_AD     = AMULTSEL || BMULTSEL;

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
    localparam Z_CONN = (Z_SEL != 3'b000) && (Z_SEL != 3'b111);
    localparam Z_ACC  = (Z_SEL == 3'b010);         // kept: used by the ACC block

    // Any operand taking the P feedback node. dsp4_top.v:390 has
    // `p_acc = PREG ? p_reg : alu_result`, so selecting P without a P register
    // closes a combinational loop through the ALU -- reject it.
    // Z = 110 (P>>17) reads p_reg just as 010 does, so it is a P-feedback mode
    // too and needs PREG -- without this the combinational-loop guard below
    // would let it through. Z = 100 (MACC_EXT) does NOT read P: it is the pure
    // sign word {64{SIGNCIN}} (ffb 4.2.6 correctness fix).
    localparam Z_READS_P = Z_ACC || (Z_SEL == 3'b110);
    localparam USES_P = (W_SEL == 2'b01) || (X_SEL == 2'b10) || Z_READS_P;

    // MREG and PREG each add one cycle between multiplier and P. With only one
    // requested, realise that stage on the ACC/P register and omit the M/MV
    // flops: same latency, one physical stage, ALU inside the registered path.
    // The dedicated M stage appears only when both are requested.
    localparam USE_MREG = (MREG && PREG);
    localparam USE_PREG = (MREG || PREG);

    // -- configurations this techmap does not implement --------------------
    // Reject rather than mis-map (see the header). Each term is a capability
    // tracked by scripts/dspv4/techmap_coverage.py in aurora2.
    localparam UNSUPPORTED =
           (CARRYINSEL != 3'b000 && CARRYINSEL != 3'b010)  // only CIN / CCIN
        || (W_SEL == 2'b10)                             // reserved W encoding
        || (Y_SEL == 2'b10)                             // reserved Y encoding
        || (A_IN_SEL || B_IN_SEL)                       // ACIN / BCIN inputs
        || (INMODE[0] || INMODE[4])                     // reg-path select, see below
        // Combinational P feedback. Tests PREG, *not* USE_PREG: the folding below
        // sets USE_PREG whenever MREG is set, so USE_PREG here would let
        // MREG=1/PREG=0 through and dsp4_top.v would have p_acc = alu_result.
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
                QL_DSP4_A1_DFFRE ff (.D(A[i]), .E(CEA), .R(RSTN), .clk(CLK), .Q(a_s0[i]));
            end
        end else begin : g_a1_byp
            assign a_s0 = A;
        end
        if (AREG1) begin : g_a2
            for (i = 0; i < 32; i = i + 1) begin : b
                QL_DSP4_A2_DFFRE ff (.D(a_s0[i]), .E(CEA), .R(RSTN), .clk(CLK), .Q(a_path[i]));
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
                QL_DSP4_B1_DFFRE ff (.D(B[i]), .E(CEB), .R(RSTN), .clk(CLK), .Q(b_s0[i]));
            end
        end else begin : g_b1_byp
            assign b_s0 = B;
        end
        if (BREG1) begin : g_b2
            for (i = 0; i < 18; i = i + 1) begin : b
                QL_DSP4_B2_DFFRE ff (.D(b_s0[i]), .E(CEB), .R(RSTN), .clk(CLK), .Q(b_path[i]));
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
                QL_DSP4_D_DFFRE ff (.D(D[i]), .E(CED), .R(RSTN), .clk(CLK), .Q(d_path[i]));
            end
        end else begin : g_d_byp
            assign d_path = D;
        end
        if (CREG) begin : g_c
            for (i = 0; i < 50; i = i + 1) begin : b
                QL_DSP4_C_DFFRE ff (.D(C[i]), .E(CEC), .R(RSTN), .clk(CLK), .Q(c_path[i]));
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
    // Operand zero-gates (INMODE[1]). Only the pre-adder side is gated on A --
    // the multiplier takes the A reg-path output ungated (dsp4_top.v:
    // mult_a = AMULTSEL ? preadd_ad : preadd_xmux, and preadd_xmux is PATH_OUT,
    // not GATE_OUT). On B the multiplier does take the gated value.
    wire [31:0] a_gate = GATE_A ? 32'b0 : a_path;
    wire [17:0] b_gate = GATE_B ? 18'b0 : b_path;
    // Pre-adder I1: B sign-extended 18 -> 32, or the A path (PREADDINSEL).
    wire [31:0] preadd_i1 = PREADDINSEL ? {{14{b_gate[17]}}, b_gate} : a_gate;
    // Pre-adder I0: D, or zero when INMODE[2] gates it off.
    wire [26:0] preadd_i0 = D_ACTIVE ? d_path : 27'b0;
    generate
        if (USE_AD) begin : g_pa
            if (PREADD_SUB) begin : g_sub
                QL_DSP4_PRESUB u_pa (.I0(preadd_i0), .I1(preadd_i1), .AD(ad_raw));
            end else begin : g_add
                QL_DSP4_PREADD u_pa (.I0(preadd_i0), .I1(preadd_i1), .AD(ad_raw));
            end
            if (ADREG) begin : g_ad
                for (i = 0; i < 32; i = i + 1) begin : b
                    QL_DSP4_AD_DFFR ff (.D(ad_raw[i]), .R(RSTN), .clk(CLK), .Q(ad_path[i]));
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
    wire [31:0] mult_i1;
    generate
        // I1 (32b): pre-adder result when AMULTSEL, else the ungated A path.
        if (AMULTSEL) begin : g_mi1_ad
            assign mult_i1 = ad_path;
        end else begin : g_mi1_a
            assign mult_i1 = a_path;
        end
        // I0 (18b): pre-adder result when BMULTSEL, else the gated B path.
        if (BMULTSEL) begin : g_mi0_ad
            assign mult_i0 = ad_path[17:0];
        end else begin : g_mi0_b
            assign mult_i0 = b_gate;
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
                QL_DSP4_M_DFFR  ff (.D(mult_u[i]), .R(RSTN), .clk(CLK), .Q(msel[i]));
            end
            // Only V[49:7] is registered -- 43 flops, not 50. V[6:0] are
            // structurally zero for the 19-row 32x18 reduction tree, so the
            // hardware does not spend flops on them (dsp4_top.v:
            // MULT_V_LSB_ZEROS = 7) and the tile has QL_DSP4_MV_DFFR num_pb=43.
            // Emitting 50 makes the pp_mreg_u molecule demand more MV flops
            // than the tile owns, and packing fails with "Can not find any
            // logic block that can implement molecule".
            for (i = 7; i < 50; i = i + 1) begin : bv
                QL_DSP4_MV_DFFR ff (.D(mult_v[i]), .R(RSTN), .clk(CLK), .Q(vsel[i]));
            end
            // V[6:0] bypass the register, matching the arch's mv_c0_d_0..6
            // directs (mult_V[6:0] -> vsel_node[6:0]). Passed through rather
            // than tied to 0 so vsel[0] stays a real net: the ALU Y upper-bit
            // pad below is {14{vsel[0]}}, and a literal 0 there has to be
            // routed in as a constant, which is what made dsp_preadder_multadd
            // unroutable.
            assign vsel[6:0] = mult_v[6:0];
            // KN pipelines in lockstep with U/V (dsp4_top.v:255) so the X-mux
            // pad stays aligned with the partial products it extends.
            QL_DSP4_MK_DFFR ffk (.D(mult_kn), .R(RSTN), .clk(CLK), .Q(knsel));
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
    //
    // This bank takes .R(ACCRSTN), not RSTN like the others. dsp4_top.v shows
    // the P register clearing on `RSTN & ACCRSTN`, but per the hardware team
    // that AND sits inside the physical mode and is not part of the interface
    // the operating mode presents: ACCRSTN alone is what a consumer drives, and
    // it is what the arch wires to this leaf. Do not add RSTN here.
    // =======================================================================
    wire [63:0] alu_out;
    wire [3:0]  alu_co;
    wire [63:0] acc_q;
    wire [63:0] p_node;
    generate
        if (USE_PREG) begin : g_acc
            for (i = 0; i < 64; i = i + 1) begin : b
                QL_DSP4_ACC_DFFRE ff (.D(alu_out[i]), .E(CEP), .R(ACCRSTN), .clk(CLK), .Q(acc_q[i]));
            end
            assign p_node = acc_q;
        end else begin : g_acc_byp
            assign acc_q  = 64'b0;   // unused (Z selects ACC.Q only when PREG=1)
            assign p_node = alu_out;
        end
    endgenerate

    // ALU operands. Each is the single fanin of its mode mux, or left open. All
    // sources sign-extend to the 64-bit accumulator width.
    //
    // A:B is the *registered* a_path / b_path, not the raw A / B ports.
    wire [63:0] u_ext    = {{14{knsel}}, msel};
    // Padded with vsel[0], not a literal 0: the tile has no independent pins
    // for the upper bits, so the arch's own source must be used or routing
    // fails. Still a true zero-extension -- V[6:0] are structurally zero.
    wire [63:0] v_ext    = {{14{vsel[0]}}, vsel};
    wire [63:0] c_ext    = {{14{c_path[49]}}, c_path};
    wire [63:0] pcin_ext = {{14{PCIN[49]}}, PCIN};
    // The >>17 Z paths take the low-50 window, shift it right by 17
    // arithmetically, and sign-extend to 64 (dsp4_top.v: pcin_shift17 /
    // p_shift17).
    wire [63:0] pcin_s17 = {{14{PCIN[49]}}, {17{PCIN[49]}}, PCIN[49:17]};
    wire [63:0] p_s17    = {{14{acc_q[49]}}, {17{acc_q[49]}}, acc_q[49:17]};
    // MACC_EXT is the sign word for the upper limb of a one-shot signed
    // multi-slice MACC -- SIGNCIN only, no P term. It used to add this slice's
    // own acc_q[49:17], which made the signed 100-bit compose wrong whenever
    // the low limb was negative (ffb 4.2.6).
    wire [63:0] macc_ext = {64{SIGNCIN}};
    wire [63:0] ab_ext   = {{14{a_path[31]}}, a_path, b_path};

    // ALU carry-in. CARRYINSEL 000 takes the fabric CIN port, 010 the cascaded
    // carry from the lower slice; both are real nets. 100 -- this slice's own
    // registered carry-out -- is rejected: without COUTREG it closes a
    // combinational loop ALU.CARRYOUT -> ALU.CIN.
    wire alu_cin = (CARRYINSEL == 3'b010) ? CCIN : CIN;

    wire [63:0] alu_w = (W_SEL == 2'b01) ? acc_q : c_ext;
    wire [63:0] alu_y = (Y_SEL == 2'b01) ? v_ext : c_ext;
    wire [63:0] alu_x = (X_SEL == 2'b01) ? u_ext :
                        (X_SEL == 2'b10) ? acc_q : ab_ext;
    wire [63:0] alu_z = (Z_SEL == 3'b001) ? pcin_ext :
                        (Z_SEL == 3'b010) ? acc_q :
                        (Z_SEL == 3'b011) ? c_ext :
                        (Z_SEL == 3'b100) ? macc_ext :
                        (Z_SEL == 3'b101) ? pcin_s17 : p_s17;

    // 4 ALU cell types x 16 operand-presence combinations. An operand that
    // selects 0 is left OPEN: the dsp4_logical mode has no constant-zero mux
    // input, so a tied 64'b0 would have nothing to route from. Generated --
    // see scripts/dspv4/ in aurora2.
    generate
    if (ALUMODE == 2'b00) begin : g_add
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_ADD #(.MODE_BITS({USE_SIMD, 2'b00})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end else if (ALUMODE == 2'b11) begin : g_sub
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_SUB #(.MODE_BITS({USE_SIMD, 2'b11})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end else if (ALUMODE == 2'b01) begin : g_rsub
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_REV_SUB #(.MODE_BITS({USE_SIMD, 2'b01})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end else if (ALUMODE == 2'b10) begin : g_nsum
        if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0000) begin : c0000
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0001) begin : c0001
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0010) begin : c0010
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0011) begin : c0011
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0100) begin : c0100
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0101) begin : c0101
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0110) begin : c0110
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b0111) begin : c0111
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1000) begin : c1000
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1001) begin : c1001
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1010) begin : c1010
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1011) begin : c1011
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1100) begin : c1100
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1101) begin : c1101
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(alu_x), .Y(), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1110) begin : c1110
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if ({W_CONN, X_CONN, Y_CONN, Z_CONN} == 4'b1111) begin : c1111
            QL_DSP4_ALU_NOT_SUM #(.MODE_BITS({USE_SIMD, 2'b10})) u_alu (.W(alu_w), .X(alu_x), .Y(alu_y), .Z(alu_z),
                                   .CIN(alu_cin), .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end

    end
    endgenerate

    // =======================================================================
    // Output stage. P = USE_RSS ? RSS(p_node) : p_node[49:0]. PCOUT mirrors P.
    // =======================================================================
    wire [49:0] p_out;
    generate
        if (USE_RSS) begin : g_rss
            // Configuration rides as a parameter; the mode has no constant source to
            // route ports from. {SATURATE, SHIFT[5:0], ROUND[2:0]} is the packing
            // QL_DSPPHY_RSS defines.
            QL_DSP4_RSS #(
                .MODE_BITS({SATURATE, SHIFT, ROUND})
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
                QL_DSP4_CO_DFFR ff (.D(alu_co[i]), .R(RSTN), .clk(CLK), .Q(cout_w[i]));
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
    // (dsp4_top.v: SIGNCOUT = p_acc[MULT_P_WIDTH-1]).
    assign SIGNCOUT = p_node[49];

    // A/B cascade outputs (registered path taps). Unused in Phase-1 designs
    // (dropped by `clean`), driven here to match the operating-mode taps.
    assign ACOUT = a_path;
    assign BCOUT = b_path;

endmodule
