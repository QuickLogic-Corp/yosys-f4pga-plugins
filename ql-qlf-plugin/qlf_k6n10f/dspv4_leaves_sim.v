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
// ===========================================================================
// dspv4_leaves_sim.v -- GENERATED FILE, DO NOT EDIT BY HAND.
//
// Regenerate with:
//     aurora2/scripts/dspv4/gen_dspv4_leaves_sim.py
// Check for staleness (CI, VR-9):
//     aurora2/scripts/dspv4/gen_dspv4_leaves_sim.py --check
//
// Simulatable bodies for the QL_DSP4_* leaves the Phase-2 techmap emits, so a
// post-synthesis netlist can be run against the golden RTL.
//
// Simulation only: NOT synthesizable, and NOT the packer-visible black boxes
// (those are in QL_DSP4_leaves.v).
//
// Derived from ffb RTL. If a digest below no longer matches ffb, --check fails:
// re-run the generator and review the diff.
//
//   QL_DSP4_MULT                       rtl/pmult.v              sha256:5cf5e388a54660bd
//   QL_DSP4_MULT                       rtl/multiplier.v         sha256:2774a077899700ff
//   QL_DSP4_ALU_*                      rtl/alu.v                sha256:900d02ed05cdaa86
//   QL_DSP4_PREADD / QL_DSP4_PRESUB    rtl/preadder.v           sha256:3269b4f9ed290fc6
//   QL_DSP4_RSS                        rtl/rss_block.v          sha256:4934a3f41b91d330
//   QL_DSP4_RSS                        rtl/round.v              sha256:e5ce9f93518b88d0
//   QL_DSP4_*_DFFR / _DFFRE            rtl/DFFE_SNR_ANR.v       sha256:c7baf42afdd97f58
// ===========================================================================

`timescale 1ns / 1ps

// ===========================================================================
// Compute macros
// ===========================================================================

// Width-50 carry-save adder (3:2 compressor), from pmult.v's `csa`
// built out of `full_adder`. sum_o + carry_o == a + b + c - k_o*2^50.
// The per-bit full adders are written as bitwise ops here; identical
// logic, one line instead of a 50-way generate.
module qldsp4_csa (a, b, c, sum_o, carry_o, k_o);
  input  wire [49:0] a, b, c;
  output wire [49:0] sum_o, carry_o;
  output wire        k_o;
  wire [49:0] cbit;
  assign sum_o   = a ^ b ^ c;
  assign cbit    = (a & b) | (a & c) | (b & c);
  // carries are weighted one position up; the top carry is dropped
  // (mod 2^50) and reported on k_o.
  assign carry_o = {cbit[48:0], 1'b0};
  assign k_o     = cbit[49];
endmodule

// 32x18 signed multiply in carry-save form, from ffb/rtl/pmult.v
// (Baugh-Wooley partial products -> Wallace 3:2 tree).
//
//   U + V == I1 * I0 + KN * 2^50    (U, V are UNSIGNED 50-bit)
//
// U is not the product: do not sign-extend it. V[6:0] is structurally 0
// for this 19-row tree, which is why MREG registers only V[49:7].
module QL_DSP4_MULT (I0, I1, U, V, KN);
  input  wire [17:0] I0;   // 18-bit multiplier   (pmult 'b')
  input  wire [31:0] I1;   // 32-bit multiplicand (pmult 'a')
  output wire [49:0] U;
  output wire [49:0] V;
  output wire        KN;

  wire [31:0] a = I1;
  wire [17:0] b = I0;

  // Stage 1: partial-product generation.
  wire [49:0] r0_0, r0_1, r0_2, r0_3, r0_4, r0_5, r0_6, r0_7, r0_8, r0_9, r0_10, r0_11, r0_12, r0_13, r0_14, r0_15, r0_16, r0_17, r0_18;
  assign r0_0 = {{18{1'b0}}, ~(a[31] & b[0]), (a[30:0] & {31{b[0]}})};
  assign r0_1 = {{17{1'b0}}, ~(a[31] & b[1]), (a[30:0] & {31{b[1]}}), {1{1'b0}}};
  assign r0_2 = {{16{1'b0}}, ~(a[31] & b[2]), (a[30:0] & {31{b[2]}}), {2{1'b0}}};
  assign r0_3 = {{15{1'b0}}, ~(a[31] & b[3]), (a[30:0] & {31{b[3]}}), {3{1'b0}}};
  assign r0_4 = {{14{1'b0}}, ~(a[31] & b[4]), (a[30:0] & {31{b[4]}}), {4{1'b0}}};
  assign r0_5 = {{13{1'b0}}, ~(a[31] & b[5]), (a[30:0] & {31{b[5]}}), {5{1'b0}}};
  assign r0_6 = {{12{1'b0}}, ~(a[31] & b[6]), (a[30:0] & {31{b[6]}}), {6{1'b0}}};
  assign r0_7 = {{11{1'b0}}, ~(a[31] & b[7]), (a[30:0] & {31{b[7]}}), {7{1'b0}}};
  assign r0_8 = {{10{1'b0}}, ~(a[31] & b[8]), (a[30:0] & {31{b[8]}}), {8{1'b0}}};
  assign r0_9 = {{9{1'b0}}, ~(a[31] & b[9]), (a[30:0] & {31{b[9]}}), {9{1'b0}}};
  assign r0_10 = {{8{1'b0}}, ~(a[31] & b[10]), (a[30:0] & {31{b[10]}}), {10{1'b0}}};
  assign r0_11 = {{7{1'b0}}, ~(a[31] & b[11]), (a[30:0] & {31{b[11]}}), {11{1'b0}}};
  assign r0_12 = {{6{1'b0}}, ~(a[31] & b[12]), (a[30:0] & {31{b[12]}}), {12{1'b0}}};
  assign r0_13 = {{5{1'b0}}, ~(a[31] & b[13]), (a[30:0] & {31{b[13]}}), {13{1'b0}}};
  assign r0_14 = {{4{1'b0}}, ~(a[31] & b[14]), (a[30:0] & {31{b[14]}}), {14{1'b0}}};
  assign r0_15 = {{3{1'b0}}, ~(a[31] & b[15]), (a[30:0] & {31{b[15]}}), {15{1'b0}}};
  assign r0_16 = {{2{1'b0}}, ~(a[31] & b[16]), (a[30:0] & {31{b[16]}}), {16{1'b0}}};
  assign r0_17 = {1'b0, (a[31] & b[17]), ~(a[30:0] & {31{b[17]}}), {17{1'b0}}};
  assign r0_18 = 50'h2000080020000;

  // Stage 2: Wallace reduction. Layer schedule matches csa_reduce's
  // recursion exactly, so U and V match ffb bit-for-bit
  // (not just their sum).

  // layer 1: 19 rows -> 13 (6 compressors, 1 passed through)
  wire [49:0] r1_0, r1_1, r1_2, r1_3, r1_4, r1_5, r1_6, r1_7, r1_8, r1_9, r1_10, r1_11, r1_12;
  wire k1_0, k1_1, k1_2, k1_3, k1_4, k1_5;
  qldsp4_csa u_csa1_0 (.a(r0_0), .b(r0_1), .c(r0_2), .sum_o(r1_0), .carry_o(r1_1), .k_o(k1_0));
  qldsp4_csa u_csa1_1 (.a(r0_3), .b(r0_4), .c(r0_5), .sum_o(r1_2), .carry_o(r1_3), .k_o(k1_1));
  qldsp4_csa u_csa1_2 (.a(r0_6), .b(r0_7), .c(r0_8), .sum_o(r1_4), .carry_o(r1_5), .k_o(k1_2));
  qldsp4_csa u_csa1_3 (.a(r0_9), .b(r0_10), .c(r0_11), .sum_o(r1_6), .carry_o(r1_7), .k_o(k1_3));
  qldsp4_csa u_csa1_4 (.a(r0_12), .b(r0_13), .c(r0_14), .sum_o(r1_8), .carry_o(r1_9), .k_o(k1_4));
  qldsp4_csa u_csa1_5 (.a(r0_15), .b(r0_16), .c(r0_17), .sum_o(r1_10), .carry_o(r1_11), .k_o(k1_5));
  assign r1_12 = r0_18;

  // layer 2: 13 rows -> 9 (4 compressors, 1 passed through)
  wire [49:0] r2_0, r2_1, r2_2, r2_3, r2_4, r2_5, r2_6, r2_7, r2_8;
  wire k2_0, k2_1, k2_2, k2_3;
  qldsp4_csa u_csa2_0 (.a(r1_0), .b(r1_1), .c(r1_2), .sum_o(r2_0), .carry_o(r2_1), .k_o(k2_0));
  qldsp4_csa u_csa2_1 (.a(r1_3), .b(r1_4), .c(r1_5), .sum_o(r2_2), .carry_o(r2_3), .k_o(k2_1));
  qldsp4_csa u_csa2_2 (.a(r1_6), .b(r1_7), .c(r1_8), .sum_o(r2_4), .carry_o(r2_5), .k_o(k2_2));
  qldsp4_csa u_csa2_3 (.a(r1_9), .b(r1_10), .c(r1_11), .sum_o(r2_6), .carry_o(r2_7), .k_o(k2_3));
  assign r2_8 = r1_12;

  // layer 3: 9 rows -> 6 (3 compressors, 0 passed through)
  wire [49:0] r3_0, r3_1, r3_2, r3_3, r3_4, r3_5;
  wire k3_0, k3_1, k3_2;
  qldsp4_csa u_csa3_0 (.a(r2_0), .b(r2_1), .c(r2_2), .sum_o(r3_0), .carry_o(r3_1), .k_o(k3_0));
  qldsp4_csa u_csa3_1 (.a(r2_3), .b(r2_4), .c(r2_5), .sum_o(r3_2), .carry_o(r3_3), .k_o(k3_1));
  qldsp4_csa u_csa3_2 (.a(r2_6), .b(r2_7), .c(r2_8), .sum_o(r3_4), .carry_o(r3_5), .k_o(k3_2));

  // layer 4: 6 rows -> 4 (2 compressors, 0 passed through)
  wire [49:0] r4_0, r4_1, r4_2, r4_3;
  wire k4_0, k4_1;
  qldsp4_csa u_csa4_0 (.a(r3_0), .b(r3_1), .c(r3_2), .sum_o(r4_0), .carry_o(r4_1), .k_o(k4_0));
  qldsp4_csa u_csa4_1 (.a(r3_3), .b(r3_4), .c(r3_5), .sum_o(r4_2), .carry_o(r4_3), .k_o(k4_1));

  // layer 5: 4 rows -> 3 (1 compressor, 1 passed through)
  wire [49:0] r5_0, r5_1, r5_2;
  wire k5_0;
  qldsp4_csa u_csa5_0 (.a(r4_0), .b(r4_1), .c(r4_2), .sum_o(r5_0), .carry_o(r5_1), .k_o(k5_0));
  assign r5_2 = r4_3;

  // layer 6: 3 rows -> 2 (1 compressor, 0 passed through)
  wire [49:0] r6_0, r6_1;
  wire k6_0;
  qldsp4_csa u_csa6_0 (.a(r5_0), .b(r5_1), .c(r5_2), .sum_o(r6_0), .carry_o(r6_1), .k_o(k6_0));

  assign U = r6_0;
  assign V = r6_1;

  // K is the dropped 2^50 carry, ORed across every layer. At most one can
  // fire, so the OR is the exact count. multiplier.v exports it inverted.
  wire k = k1_0 | k1_1 | k1_2 | k1_3 | k1_4 | k1_5 | k2_0 | k2_1 | k2_2 | k2_3 | k3_0 | k3_1 | k3_2 | k4_0 | k4_1 | k5_0 | k6_0;
  assign KN = ~k;
endmodule

// Shared ALU core, from ffb/rtl/alu.v with ALUMODE baked in as MODE. The SIMD
// segmented path is included: USE_SIMD arrives as a cell parameter, the same way
// QL_DSP4_RSS takes ROUND/SHIFT/SATURATE.
//   00 ADD      : ALU_OUT = W + X + Y + Z + CIN
//   01 REV_SUB  : ALU_OUT = -Z + (W + X + Y + CIN) - 1
//   10 NOT_SUM  : ALU_OUT = -(Z + W + X + Y + CIN) - 1
//   11 SUB      : ALU_OUT = Z - (W + X + Y + CIN)
module qldsp4_alu_core #(
    parameter [1:0] MODE     = 2'b00,
    parameter [1:0] USE_SIMD = 2'b00
) (
    input  wire [63:0] W,
    input  wire [63:0] X,
    input  wire [63:0] Y,
    input  wire [63:0] Z,
    input  wire        CIN,
    output wire [63:0] ALU_OUT,
    output wire [3:0]  CARRYOUT
);
  // Coerce undriven (open -> z) / x input bits to 0: an unused ALU mux leg is a
  // constant 0 in hardware, but the Phase-2 netlist simply leaves it open.
  function [63:0] cz64;
    input [63:0] v;
    integer i;
    begin
      for (i = 0; i < 64; i = i + 1) cz64[i] = (v[i] === 1'b1);
    end
  endfunction

  wire [63:0] Wc   = cz64(W);
  wire [63:0] Xc   = cz64(X);
  wire [63:0] Yc   = cz64(Y);
  wire [63:0] Zc   = cz64(Z);
  wire        CINc = (CIN === 1'b1);

  wire [63:0] wxy     = Wc + Xc + Yc;
  wire [63:0] z_eff   = (MODE[0] ^ MODE[1]) ? ~Zc : Zc;
  wire [63:0] wxy_eff = MODE[1] ? ~wxy : wxy;
  wire        cin_eff = MODE[1] ? ~CINc : CINc;

  wire [64:0] full_sum = {1'b0, z_eff} + {1'b0, wxy_eff} + cin_eff;

  // --- SIMD segmented path (alu.v). Four 12-bit segments; carry is blocked at
  // the segment boundaries per USE_SIMD. TWO24 lets carry cross seg0->seg1 and
  // seg2->seg3 but never the 24-bit boundary; FOUR12 blocks all of them and
  // injects cin_eff into each segment so every one gets its own +1 for a
  // two's-complement subtract.
  wire [12:0] simd_s0 = {1'b0, z_eff[11:0]}  + {1'b0, wxy_eff[11:0]}  + cin_eff;
  wire        simd_c0 = simd_s0[12];
  wire        simd_c1_in = (USE_SIMD == 2'b10) ? cin_eff : simd_c0;
  wire [12:0] simd_s1 = {1'b0, z_eff[23:12]} + {1'b0, wxy_eff[23:12]} + simd_c1_in;
  wire        simd_c1 = simd_s1[12];
  wire [12:0] simd_s2 = {1'b0, z_eff[35:24]} + {1'b0, wxy_eff[35:24]} + cin_eff;
  wire        simd_c2 = simd_s2[12];
  wire        simd_c3_in = (USE_SIMD == 2'b10) ? cin_eff : simd_c2;
  wire [12:0] simd_s3 = {1'b0, z_eff[47:36]} + {1'b0, wxy_eff[47:36]} + simd_c3_in;
  wire        simd_c3 = simd_s3[12];

  wire [63:0] simd_result =
      {14'b0, simd_s3[11:0], simd_s2[11:0], simd_s1[11:0], simd_s0[11:0]};

  assign ALU_OUT = (USE_SIMD == 2'b00) ? full_sum[63:0] : simd_result;

  // CARRYOUT[3] = carry out of bit 49 (the 50-bit P / PCOUT cascade boundary,
  // alu.v's CASC_BIT) in the 1x50 path. In TWO24 only [1] and [3] are the real
  // segment carries -- [0] and [2] are intra-half intermediates and read 0. In
  // FOUR12 all four are valid.
  wire cascade_carry = full_sum[50] ^ z_eff[50] ^ wxy_eff[50];
  assign CARRYOUT =
      (USE_SIMD == 2'b00) ? {cascade_carry, 3'b000} :
      (USE_SIMD == 2'b01) ? {simd_c3, 1'b0, simd_c1, 1'b0}
                          : {simd_c3, simd_c2, simd_c1, simd_c0};
endmodule

module QL_DSP4_ALU_ADD (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  // One combined word, matching the arch's four reserved mode bits:
  //   MODE_BITS[1:0] ALUMODE   MODE_BITS[3:2] USE_SIMD
  // ALUMODE is implied by which leaf this is, so only the USE_SIMD half is
  // read here. Declared and forwarded: a parameter left unconnected silently
  // takes the default, which is the bug class this DSP keeps producing.
  parameter [3:0] MODE_BITS = 4'b0000;
  wire [1:0] USE_SIMD = MODE_BITS[3:2];
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b00), .USE_SIMD(MODE_BITS[3:2])) u (
      .W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
      .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

module QL_DSP4_ALU_REV_SUB (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  // One combined word, matching the arch's four reserved mode bits:
  //   MODE_BITS[1:0] ALUMODE   MODE_BITS[3:2] USE_SIMD
  // ALUMODE is implied by which leaf this is, so only the USE_SIMD half is
  // read here. Declared and forwarded: a parameter left unconnected silently
  // takes the default, which is the bug class this DSP keeps producing.
  parameter [3:0] MODE_BITS = 4'b0000;
  wire [1:0] USE_SIMD = MODE_BITS[3:2];
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b01), .USE_SIMD(MODE_BITS[3:2])) u (
      .W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
      .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

module QL_DSP4_ALU_NOT_SUM (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  // One combined word, matching the arch's four reserved mode bits:
  //   MODE_BITS[1:0] ALUMODE   MODE_BITS[3:2] USE_SIMD
  // ALUMODE is implied by which leaf this is, so only the USE_SIMD half is
  // read here. Declared and forwarded: a parameter left unconnected silently
  // takes the default, which is the bug class this DSP keeps producing.
  parameter [3:0] MODE_BITS = 4'b0000;
  wire [1:0] USE_SIMD = MODE_BITS[3:2];
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b10), .USE_SIMD(MODE_BITS[3:2])) u (
      .W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
      .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

module QL_DSP4_ALU_SUB (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  // One combined word, matching the arch's four reserved mode bits:
  //   MODE_BITS[1:0] ALUMODE   MODE_BITS[3:2] USE_SIMD
  // ALUMODE is implied by which leaf this is, so only the USE_SIMD half is
  // read here. Declared and forwarded: a parameter left unconnected silently
  // takes the default, which is the bug class this DSP keeps producing.
  parameter [3:0] MODE_BITS = 4'b0000;
  wire [1:0] USE_SIMD = MODE_BITS[3:2];
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b11), .USE_SIMD(MODE_BITS[3:2])) u (
      .W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
      .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

// Pre-adder, from ffb/rtl/preadder.v: AD is the two's-complement low 32 bits
// of I0 +/- I1, with I0 the 27-bit D operand and I1 the 32-bit operand.
// INMODE3 = 0 -> add, 1 -> subtract.
//
// It WRAPS on overflow and produces no overflow flag. Saturation was removed
// in ffb 4.2.5; before that, same-sign additions clamped to the 32-bit signed
// range while subtract and mixed-sign operands wrapped. Do not reintroduce the
// clamp -- ql_dspv4 warns the user about the overflow risk instead.
module qldsp4_preadder #(
    parameter INMODE3 = 1'b0
) (
    input  wire [26:0] I0,
    input  wire [31:0] I1,
    output wire [31:0] AD
);
  wire signed [26:0] I0_s = I0;
  wire signed [31:0] I1_s = I1;
  wire signed [32:0] raw  = INMODE3 ? (I0_s - I1_s) : (I0_s + I1_s);

  assign AD = raw[31:0];
endmodule

module QL_DSP4_PREADD (I0, I1, AD);
  input  wire [26:0] I0;
  input  wire [31:0] I1;
  output wire [31:0] AD;
  qldsp4_preadder #(.INMODE3(1'b0)) u (.I0(I0), .I1(I1), .AD(AD));
endmodule

module QL_DSP4_PRESUB (I0, I1, AD);
  input  wire [26:0] I0;
  input  wire [31:0] I1;
  output wire [31:0] AD;
  qldsp4_preadder #(.INMODE3(1'b1)) u (.I0(I0), .I1(I1), .AD(AD));
endmodule

// Rounder, from ffb/rtl/round.v. Rounds so the low `frac_bits_i` bits can be
// truncated by the shift downstream; the mode only decides how an exact 0.5
// breaks. Values that are not exactly 0.5 always go to the nearest integer.
module qldsp4_round (a_i, round_mode_i, frac_bits_i, z_o);
  input  wire [63:0] a_i;
  input  wire [ 2:0] round_mode_i;
  input  wire [ 5:0] frac_bits_i;
  output wire [63:0] z_o;

  localparam [2:0] RMODE_NONE = 3'b000;  // no rounding
  localparam [2:0] RMODE_RHUA = 3'b001;  // round half up, asymmetrical
  localparam [2:0] RMODE_RHUS = 3'b010;  // round half up, symmetrical
  localparam [2:0] RMODE_RHDS = 3'b011;  // round half down, symmetrical
  localparam [2:0] RMODE_RHE  = 3'b100;  // round half even
  localparam [2:0] RMODE_RHO  = 3'b101;  // round half odd

  wire signed [63:0] a_in    = $signed(a_i);
  wire               a_sign  = a_in[63];
  wire signed [63:0] onehalf = (frac_bits_i == 6'b0)
                             ? 64'b0
                             : ({{63{1'b0}}, 1'b1} << (frac_bits_i - 1));
  wire        [63:0] int_mask  = ({64{1'b1}} << frac_bits_i);
  wire        [63:0] frac_mask = ~int_mask;
  wire signed [63:0] a_frac    = a_i & frac_mask;
  wire signed [63:0] a_int     = a_in >>> frac_bits_i;
  reg  signed [63:0] z_out;

  always @* begin
    case (round_mode_i)
      RMODE_NONE: z_out = a_in;
      RMODE_RHUA: z_out = a_in + onehalf;
      RMODE_RHUS: // negative and exactly 0.5 -> leave; else add 1/2
        if ((a_sign == 1'b1) && (a_frac == onehalf)) z_out = a_in;
        else z_out = a_in + onehalf;
      RMODE_RHDS: // positive and exactly 0.5 -> leave; else add 1/2
        if ((a_sign == 1'b0) && (a_frac == onehalf)) z_out = a_in;
        else z_out = a_in + onehalf;
      RMODE_RHE:  // even and exactly 0.5 -> leave; else add 1/2
        if ((a_int[0] == 1'b0) && (a_frac == onehalf)) z_out = a_in;
        else z_out = a_in + onehalf;
      RMODE_RHO:  // odd and exactly 0.5 -> leave; else add 1/2
        if ((a_int[0] == 1'b1) && (a_frac == onehalf)) z_out = a_in;
        else z_out = a_in + onehalf;
      default: z_out = a_in;
    endcase
  end

  assign z_o = z_out;
endmodule

// Round / arithmetic-right-shift / saturate, from ffb/rtl/rss_block.v.
// Windows the 64-bit accumulator down to the 50-bit P output.
//
// ROUND / SHIFT / SATURATE arrive as *parameters*, not ports: on this path
// configuration reaches a leaf as a parameter (the precedent is QL_DSPV2_MULT's
// MODE_BITS), and ports would need routing from a constant source that the
// operating mode has no provision for. The techmap passes the QL_DSP4
// parameters straight through. The physical macro QL_DSPPHY_RSS packs them as
// one word, mode = {SATURATE, SHIFT[5:0], ROUND[2:0]}; keeping them separate
// and named here matches QL_DSP4's own parameter names and stays readable in
// the BLIF, and that packing is then one documented rule for the FASM side.
module QL_DSP4_RSS (ACC_IN, ACC_OUT);
  // One combined config word; see QL_DSP4_leaves.v for the packing.
  //   MODE_BITS[2:0] ROUND   MODE_BITS[8:3] SHIFT   MODE_BITS[9] SATURATE
  parameter [9:0] MODE_BITS = 10'b0;
  wire [2:0] ROUND    = MODE_BITS[2:0];
  wire [5:0] SHIFT    = MODE_BITS[8:3];
  wire       SATURATE = MODE_BITS[9];

  input  wire [63:0] ACC_IN;
  output wire [49:0] ACC_OUT;

  localparam Z_WIDTH = 50;

  wire signed [63:0] acc_round;
  qldsp4_round u_round (
      .a_i         (ACC_IN),
      .round_mode_i(ROUND),
      .frac_bits_i (SHIFT),
      .z_o         (acc_round)
  );

  wire signed [63:0] acc_shift = (acc_round >>> SHIFT);
  reg  signed [63:0] acc_saturate;

  always @* begin
    if (!SATURATE) begin
      acc_saturate = acc_shift;
    end else begin
      // In range iff every bit above the 50-bit window matches the sign bit.
      if ((|acc_shift[63:Z_WIDTH-1] == 1'b0) ||
          (&acc_shift[63:Z_WIDTH-1] == 1'b1)) begin
        acc_saturate = {{(64 - Z_WIDTH) {1'b0}}, {acc_shift[Z_WIDTH-1:0]}};
      end else begin
        // Clamp to the largest magnitude of the correct sign.
        acc_saturate = {
          {(64 - Z_WIDTH) {1'b0}},
          {acc_shift[63], {Z_WIDTH - 1{~acc_shift[63]}}}
        };
      end
    end
  end

  // dsp4_top takes P from rss_block's low 50 bits.
  assign ACC_OUT = acc_saturate[49:0];
endmodule

// Pipeline registers, bit-sliced, from ffb/rtl/DFFE_SNR_ANR.v.
//   *_DFFRE : async reset R (active-low), clock-enable E
//   *_DFFR  : async reset R (active-low), no enable
// Q powers up to 0, keeping the netlist cycle-aligned with reset-to-0
// golden RTL -- the netlist ties R to 1'b1 in a functional run.

`define QL_DSP4_DFFRE(NAME) \
module NAME (D, E, R, clk, Q);      \
  input  wire D, E, R, clk;         \
  output reg  Q;                    \
  initial Q = 1'b0;                 \
  always @(posedge clk or negedge R)\
    if (!R)     Q <= 1'b0;          \
    else if (E) Q <= D;             \
endmodule

`define QL_DSP4_DFFR(NAME) \
module NAME (D, R, clk, Q);         \
  input  wire D, R, clk;            \
  output reg  Q;                    \
  initial Q = 1'b0;                 \
  always @(posedge clk or negedge R)\
    if (!R) Q <= 1'b0;              \
    else    Q <= D;                 \
endmodule

`QL_DSP4_DFFRE(QL_DSP4_A1_DFFRE)
`QL_DSP4_DFFRE(QL_DSP4_A2_DFFRE)
`QL_DSP4_DFFRE(QL_DSP4_B1_DFFRE)
`QL_DSP4_DFFRE(QL_DSP4_B2_DFFRE)
`QL_DSP4_DFFRE(QL_DSP4_D_DFFRE)
`QL_DSP4_DFFRE(QL_DSP4_C_DFFRE)
`QL_DSP4_DFFRE(QL_DSP4_ACC_DFFRE)

`QL_DSP4_DFFR(QL_DSP4_AD_DFFR)
`QL_DSP4_DFFR(QL_DSP4_M_DFFR)
`QL_DSP4_DFFR(QL_DSP4_MV_DFFR)
`QL_DSP4_DFFR(QL_DSP4_MK_DFFR)
`QL_DSP4_DFFR(QL_DSP4_CO_DFFR)
