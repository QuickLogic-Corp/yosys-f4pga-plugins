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
// QL_DSP4_* leaf cells - the packer-visible primitives of the VPR `dsp4_logical`
// operating mode (DSP-V4, Phase 2). The Phase-2 techmap (`dsp4_logical_map.v`)
// decomposes the monolithic `QL_DSP4` base cell into a netlist of these leaves,
// bit-sliced and wired per the `dsp4_logical` interconnect so the design packs
// onto the DSPV4 tile.
//
// Interface contract (names + widths) MUST match the VPR leaves exactly
// (openphy-turnkey-flow .../arch/mako/vpr_models.yaml DSPV4 section + the
// FPGA0806 rendered `dsp4_logical` pb_types). These are hard-block macros:
// read with `read_verilog -lib -specify -nomem2reg` they are interface-only
// black boxes and carry through `write_blif` as `.subckt QL_DSP4_*` for VPR
// packing. The compute leaves mirror the physical macros in
// openphy-turnkey-flow/.../custom_modules/ql_dsp_phy_cells.v, except ALUMODE /
// INMODE[3] are baked into distinct cell names (ADD/SUB/REV_SUB/NOT_SUM,
// PREADD/PRESUB) rather than a `mode` bus - the operating leaves have no config
// ports (the arithmetic is fixed by the cell type; muxes are fabric routing).

// ===========================================================================
// Compute macros
// ===========================================================================

// 32x18 signed multiply, two 50-bit partial products U (sum) and V (carry);
// U + V = I1 * I0. The final add is deferred to the ALU (U->X mux, V->Y mux).
(* blackbox *)
module QL_DSP4_MULT (I0, I1, U, V);
    input  wire [17:0] I0;
    input  wire [31:0] I1;
    output wire [49:0] U;
    output wire [49:0] V;
endmodule

// Pre-adder, add:  AD = I0 + I1   (I0 = D[26:0], I1 = 32-bit operand).
(* blackbox *)
module QL_DSP4_PREADD (I0, I1, AD);
    input  wire [26:0] I0;
    input  wire [31:0] I1;
    output wire [31:0] AD;
endmodule

// Pre-adder, subtract:  AD = I0 - I1.
(* blackbox *)
module QL_DSP4_PRESUB (I0, I1, AD);
    input  wire [26:0] I0;
    input  wire [31:0] I1;
    output wire [31:0] AD;
endmodule

// ALU: ALU_OUT = W + X + Y + Z + CIN, ALUMODE = 00 (add).
(* blackbox *)
module QL_DSP4_ALU_ADD (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
    input  wire [63:0] W;
    input  wire [63:0] X;
    input  wire [63:0] Y;
    input  wire [63:0] Z;
    input  wire        CIN;
    output wire [63:0] ALU_OUT;
    output wire [3:0]  CARRYOUT;
endmodule

// ALU, ALUMODE = 11 (subtract):  ALU_OUT = Z - (W + X + Y + CIN).
(* blackbox *)
module QL_DSP4_ALU_SUB (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
    input  wire [63:0] W;
    input  wire [63:0] X;
    input  wire [63:0] Y;
    input  wire [63:0] Z;
    input  wire        CIN;
    output wire [63:0] ALU_OUT;
    output wire [3:0]  CARRYOUT;
endmodule

// ALU, ALUMODE = 01 (reverse subtract):  ALU_OUT = -Z + (W + X + Y + CIN) - 1.
(* blackbox *)
module QL_DSP4_ALU_REV_SUB (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
    input  wire [63:0] W;
    input  wire [63:0] X;
    input  wire [63:0] Y;
    input  wire [63:0] Z;
    input  wire        CIN;
    output wire [63:0] ALU_OUT;
    output wire [3:0]  CARRYOUT;
endmodule

// ALU, ALUMODE = 10 (not-sum):  ALU_OUT = -(Z + W + X + Y + CIN) - 1.
(* blackbox *)
module QL_DSP4_ALU_NOT_SUM (W, X, Y, Z, CIN, ALU_OUT, CARRYOUT);
    input  wire [63:0] W;
    input  wire [63:0] X;
    input  wire [63:0] Y;
    input  wire [63:0] Z;
    input  wire        CIN;
    output wire [63:0] ALU_OUT;
    output wire [3:0]  CARRYOUT;
endmodule

// Round / arithmetic-right-shift / saturate: 64-bit accumulator -> 50-bit P.
(* blackbox *)
module QL_DSP4_RSS (ACC_IN, ACC_OUT);
    input  wire [63:0] ACC_IN;
    output wire [49:0] ACC_OUT;
endmodule

// ===========================================================================
// Pipeline registers (bit-sliced: one 1-bit instance per data bit)
//
//   *_DFFRE : D flip-flop, async reset R (active-low), clock-enable E.
//   *_DFFR  : D flip-flop, async reset R (active-low), no enable.
// (No SI/SO/LR - scan and local sync-reset are physical-mode-only.)
// ===========================================================================

(* blackbox *)
module QL_DSP4_A1_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_A2_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_B1_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_B2_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_D_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_C_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_ACC_DFFRE (D, E, R, clk, Q);
    input  wire D;
    input  wire E;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_AD_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_M_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_MV_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_CO_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_CCO_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

(* blackbox *)
module QL_DSP4_SCO_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule
