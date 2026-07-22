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
// Scope = Phase-1 configurations only (Appendix A of the Phase-1 requirements):
// MULT, MULTACC(+-), MULTADD(+-), PREADDER_MULT(+-), PREADDER_MULTADD, and the
// fused CONCAT+MULTADD / CONCAT+PREADDER_MULTADD (addend on C). For all of these
// X<-U, Y<-V, W open, CIN open, and Z is one of {open, ACC.Q, PCIN, C}.
//
// Sources of truth: function = behavioral_model/dspv4_sim.v; exact leaf
// interface + wiring = FPGA0806 vpr-rendered.xml `<mode name="dsp4_logical">`.

module QL_DSP4 #(
    parameter [8:0] OPMODE      = 9'b000000101,  // W[8:7] Z[6:4] Y[3:2] X[1:0]
    parameter [1:0] ALUMODE     = 2'b00,         // 00 add, 11 sub, 01 rsub, 10 not
    parameter [4:0] INMODE      = 5'b00000,      // [2]=pre-adder active, [3]=pre-adder sub
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
    localparam USE_PREADD = INMODE[2];             // pre-adder active
    localparam PREADD_SUB = INMODE[3];             // pre-adder subtract
    // Z operand select (OPMODE[6:4]): 001=PCIN, 010=P(acc feedback), 011=C.
    localparam Z_PCIN = (OPMODE[6:4] == 3'b001);
    localparam Z_ACC  = (OPMODE[6:4] == 3'b010);
    localparam Z_C    = (OPMODE[6:4] == 3'b011);
    localparam Z_CONN = (Z_PCIN || Z_ACC || Z_C);  // else Z is 0 (leave open)

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

    wire [49:0] mult_u, mult_v;
    QL_DSP4_MULT u_mult (.I0(mult_i0), .I1(mult_i1), .U(mult_u), .V(mult_v));

    // =======================================================================
    // Multiplier-output registers (MREG registers both partial products).
    // =======================================================================
    wire [49:0] msel, vsel;
    generate
        if (MREG) begin : g_m
            for (i = 0; i < 50; i = i + 1) begin : bu
                QL_DSP4_M_DFFR  ff (.D(mult_u[i]), .R(ARSTN), .clk(CLK), .Q(msel[i]));
            end
            for (i = 0; i < 50; i = i + 1) begin : bv
                QL_DSP4_MV_DFFR ff (.D(mult_v[i]), .R(ARSTN), .clk(CLK), .Q(vsel[i]));
            end
        end else begin : g_m_byp
            assign msel = mult_u;
            assign vsel = mult_v;
        end
    endgenerate

    // =======================================================================
    // Accumulator register (PREG). Feeds the P output and, for MULTACC, the ALU
    // Z operand (P feedback). ALU_OUT / acc feedback are declared first.
    // =======================================================================
    wire [63:0] alu_out;
    wire [3:0]  alu_co;
    wire [63:0] acc_q;
    wire [63:0] p_node;
    generate
        if (PREG) begin : g_acc
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
    // ALU. X <- sext(U), Y <- sext(V) (always). W, CIN left open (= 0). Z is
    // one leaf-selected source or left open (= 0) per OPMODE[6:4]. The ALU
    // variant is fixed by ALUMODE via the cell type.
    // =======================================================================
    wire [63:0] alu_x = {{14{msel[49]}}, msel};
    wire [63:0] alu_y = {{14{vsel[49]}}, vsel};

    // Z source (valid only when Z_CONN).
    wire [63:0] alu_z;
    generate
        if (Z_ACC) begin : g_z_acc
            assign alu_z = acc_q;
        end else if (Z_PCIN) begin : g_z_pcin
            assign alu_z = {{14{PCIN[49]}}, PCIN};
        end else if (Z_C) begin : g_z_c
            assign alu_z = {{14{c_path[49]}}, c_path};
        end else begin : g_z_zero
            assign alu_z = 64'b0;    // unused (ALU instantiated with Z open)
        end
    endgenerate

    generate
        if (ALUMODE == 2'b00) begin : g_alu_add
            if (Z_CONN) begin : zc
                QL_DSP4_ALU_ADD u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z), .CIN(),
                                       .ALU_OUT(alu_out), .CARRYOUT(alu_co));
            end else begin : zo
                QL_DSP4_ALU_ADD u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(), .CIN(),
                                       .ALU_OUT(alu_out), .CARRYOUT(alu_co));
            end
        end else if (ALUMODE == 2'b11) begin : g_alu_sub
            QL_DSP4_ALU_SUB u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z), .CIN(),
                                   .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else if (ALUMODE == 2'b01) begin : g_alu_rsub
            QL_DSP4_ALU_REV_SUB u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z), .CIN(),
                                       .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end else begin : g_alu_not
            QL_DSP4_ALU_NOT_SUM u_alu (.W(), .X(alu_x), .Y(alu_y), .Z(alu_z), .CIN(),
                                       .ALU_OUT(alu_out), .CARRYOUT(alu_co));
        end
    endgenerate

    // =======================================================================
    // Output stage. P = USE_RSS ? RSS(p_node) : p_node[49:0]. PCOUT mirrors P.
    // =======================================================================
    wire [49:0] p_out;
    generate
        if (USE_RSS) begin : g_rss
            QL_DSP4_RSS u_rss (.ACC_IN(p_node), .ACC_OUT(p_out));
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
    assign CCOUT = cout_w[3];             // cascade carry = top carry-out
    assign SIGNCOUT = msel[49];           // product sign

    // A/B cascade outputs (registered path taps). Unused in Phase-1 designs
    // (dropped by `clean`), driven here to match the operating-mode taps.
    assign ACOUT = a_path;
    assign BCOUT = b_path;

endmodule
