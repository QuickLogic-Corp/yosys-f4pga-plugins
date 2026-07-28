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
// dspv4_leaves_sim.v
//
// Behavioral simulation models for the QL_DSP4_* leaf cells emitted by the
// DSP-V4 Phase-2 techmap (dsp4_logical_map.v).  The Phase-2 post-synthesis
// netlist (<design>_post_synth.v) instantiates ONLY these leaves; this file
// gives each of them a simulatable body so the netlist can be run in a
// functional (post-synthesis) simulation and checked against the golden RTL.
//
// The behavior mirrors the operating-mode datapath of the monolithic
// behavioral model dspv4_sim.v (the compute macros `alu`, `multiplier`/`pmult`,
// `preadder`, `rss_block`): each leaf reproduces the exact arithmetic that the
// arch/synthesis contract assumes for that macro.  These are simulation-only
// models -- they are NOT synthesizable and NOT the packer-visible black boxes
// (those live in QL_DSP4_leaves.v).
//
// Modeling notes:
//  * In the non-accumulate operating modes the ALU W / Z / CIN inputs are left
//    open in the netlist (the mode's constant-0 mux input is not emitted).  An
//    open input reads as `z`, so the ALU leaves coerce every input bit with
//    `=== 1'b1` (1 stays 1; 0 / x / z -> 0), which reflects the intended
//    "unused mux leg drives 0" hardware behavior instead of poisoning the sum
//    with x.
//  * The bit-sliced pipeline flops power up to 0 (`initial Q = 1'b0`) so the
//    netlist and the reset-to-0 golden RTL are cycle-aligned; the netlist ties
//    each flop's async reset R to 1'b1 (reset is a physical-mode-only feature),
//    so this power-up value is what a functional run actually sees.
// ===========================================================================

`timescale 1ns / 1ps

// ===========================================================================
// Compute macros
// ===========================================================================

// 32x18 signed multiply, product returned in carry-save form: U = full signed
// product, V = 0.  U + V is resolved downstream by the ALU (U->X, V->Y).
module QL_DSP4_MULT (I0, I1, U, V);
  input  wire [17:0] I0;
  input  wire [31:0] I1;
  output wire [49:0] U;
  output wire [49:0] V;
  assign U = $signed(I1) * $signed(I0);
  assign V = 50'b0;
endmodule

// Shared ALU core.  MODE selects the ALUMODE[1:0] arithmetic (matches
// dspv4_sim.v `alu`, ONE50 / non-SIMD path):
//   00 ADD      : ALU_OUT = W + X + Y + Z + CIN
//   01 REV_SUB  : ALU_OUT = -Z + (W + X + Y + CIN) - 1
//   10 NOT_SUM  : ALU_OUT = -(Z + W + X + Y + CIN) - 1
//   11 SUB      : ALU_OUT = Z - (W + X + Y + CIN)
module qldsp4_alu_core #(
    parameter [1:0] MODE = 2'b00
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
  assign ALU_OUT = full_sum[63:0];

  // CARRYOUT[3] = carry into bit 50 (the 50-bit P / PCOUT cascade boundary);
  // the other carry bits are SIMD-only and 0 here.
  wire cascade_carry = full_sum[50] ^ z_eff[50] ^ wxy_eff[50];
  assign CARRYOUT = {cascade_carry, 3'b000};
endmodule

module QL_DSP4_ALU_ADD (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b00)) u (.W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
                                     .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

module QL_DSP4_ALU_REV_SUB (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b01)) u (.W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
                                     .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

module QL_DSP4_ALU_NOT_SUM (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b10)) u (.W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
                                     .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

module QL_DSP4_ALU_SUB (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
  input  wire [63:0] W, X, Y, Z;
  input  wire        CIN;
  output wire [63:0] ALU_OUT;
  output wire [3:0]  CARRYOUT;
  qldsp4_alu_core #(.MODE(2'b11)) u (.W(W), .X(X), .Y(Y), .Z(Z), .CIN(CIN),
                                     .ALU_OUT(ALU_OUT), .CARRYOUT(CARRYOUT));
endmodule

// Pre-adder core (matches dspv4_sim.v `preadder`): AD = saturate(I0 +/- I1).
// INMODE3 = 0 -> add, 1 -> subtract.  I0 = 27-bit (D), I1 = 32-bit operand.
module qldsp4_preadder #(
    parameter INMODE3 = 1'b0
) (
    input  wire [26:0] I0,
    input  wire [31:0] I1,
    output reg  [31:0] AD
);
  wire signed [26:0] I0_s = I0;
  wire signed [31:0] I1_s = I1;
  wire signed [32:0] raw  = INMODE3 ? (I0_s - I1_s) : (I0_s + I1_s);

  always @* begin
    if (!I1[31] && !INMODE3 && !I0[26])       // pos + pos -> clamp max +
      AD = raw[31] ? {1'b0, {31{1'b1}}} : raw[31:0];
    else if (I1[31] && !INMODE3 && I0[26])    // neg + neg -> clamp min -
      AD = !raw[31] ? {1'b1, {31{1'b0}}} : raw[31:0];
    else
      AD = raw[31:0];
  end
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

// Round / arithmetic-right-shift / saturate.  The leaf carries no config ports
// (ROUND / SHIFT / SATURATE are baked to 0 in the operating modes exercised by
// the unit designs), so this reduces to a straight 64->50 window pass-through.
module QL_DSP4_RSS (ACC_IN, ACC_OUT);
  input  wire [63:0] ACC_IN;
  output wire [49:0] ACC_OUT;
  assign ACC_OUT = ACC_IN[49:0];
endmodule

// ===========================================================================
// Pipeline registers (bit-sliced: one 1-bit instance per data bit)
//   *_DFFRE : async reset R (active-low), clock-enable E
//   *_DFFR  : async reset R (active-low), no enable
// Q powers up to 0 for cycle-alignment with the reset-to-0 golden RTL.
// ===========================================================================

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
`QL_DSP4_DFFR(QL_DSP4_CO_DFFR)
`QL_DSP4_DFFR(QL_DSP4_CCO_DFFR)
`QL_DSP4_DFFR(QL_DSP4_SCO_DFFR)
