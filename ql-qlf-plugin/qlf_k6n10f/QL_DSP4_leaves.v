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

// 32x18 signed multiply, two 50-bit partial products U (sum) and V (carry)
// plus the dropped-carry flag KN:
//
//     U + V = I1 * I0 + KN * 2^50        (U and V read as UNSIGNED)
//
// The final add is deferred to the ALU (U->X mux, V->Y mux), which resolves the
// pair as {14{KN}, U} + {14'b0, V}. U is a partial product, not the product --
// it must NOT be sign-extended. Matches the physical macro
// QL_DSPPHY_MULT (I0, I1, U, V, KN) and the VPR QL_DSP4_MULT model.
(* blackbox *)
module QL_DSP4_MULT (I0, I1, U, V, KN);
    input  wire [17:0] I0;
    input  wire [31:0] I1;
    output wire [49:0] U;
    output wire [49:0] V;
    output wire        KN;
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
    // One combined configuration word, matching the four mode bits the
    // architecture already reserves for this cell:
    //
    //   MODE_BITS[1:0] ALUMODE      MODE_BITS[3:2] USE_SIMD
    //
    // openfpga.xml carries the ALUMODE half as each mode's default, written
    // LSB-first -- REV_SUB is "1000", i.e. 4'b0001 = {USE_SIMD 00, ALUMODE 01}.
    // USE_SIMD: 00 one 50-bit add, 01 dual 24-bit, 10 quad 12-bit.
    parameter [3:0] MODE_BITS = 4'b0000;
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
    // One combined configuration word, matching the four mode bits the
    // architecture already reserves for this cell:
    //
    //   MODE_BITS[1:0] ALUMODE      MODE_BITS[3:2] USE_SIMD
    //
    // openfpga.xml carries the ALUMODE half as each mode's default, written
    // LSB-first -- REV_SUB is "1000", i.e. 4'b0001 = {USE_SIMD 00, ALUMODE 01}.
    // USE_SIMD: 00 one 50-bit add, 01 dual 24-bit, 10 quad 12-bit.
    parameter [3:0] MODE_BITS = 4'b0000;
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
    // One combined configuration word, matching the four mode bits the
    // architecture already reserves for this cell:
    //
    //   MODE_BITS[1:0] ALUMODE      MODE_BITS[3:2] USE_SIMD
    //
    // openfpga.xml carries the ALUMODE half as each mode's default, written
    // LSB-first -- REV_SUB is "1000", i.e. 4'b0001 = {USE_SIMD 00, ALUMODE 01}.
    // USE_SIMD: 00 one 50-bit add, 01 dual 24-bit, 10 quad 12-bit.
    parameter [3:0] MODE_BITS = 4'b0000;
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
    // One combined configuration word, matching the four mode bits the
    // architecture already reserves for this cell:
    //
    //   MODE_BITS[1:0] ALUMODE      MODE_BITS[3:2] USE_SIMD
    //
    // openfpga.xml carries the ALUMODE half as each mode's default, written
    // LSB-first -- REV_SUB is "1000", i.e. 4'b0001 = {USE_SIMD 00, ALUMODE 01}.
    // USE_SIMD: 00 one 50-bit add, 01 dual 24-bit, 10 quad 12-bit.
    parameter [3:0] MODE_BITS = 4'b0000;
    input  wire [63:0] W;
    input  wire [63:0] X;
    input  wire [63:0] Y;
    input  wire [63:0] Z;
    input  wire        CIN;
    output wire [63:0] ALU_OUT;
    output wire [3:0]  CARRYOUT;
endmodule

// Round / arithmetic-right-shift / saturate: 64-bit accumulator -> 50-bit P.
//
// The configuration arrives as parameters rather than ports: on this path a
// leaf takes its configuration as a parameter (precedent: QL_DSPV2_MULT's
// MODE_BITS, which ql_dspv2_types preserves), and ports would have to be routed
// from a constant source that the operating mode does not provide.
//
// The physical macro QL_DSPPHY_RSS (ACC_IN, mode, ACC_OUT) packs the three into
// one word, mode = {SATURATE, SHIFT[5:0], ROUND[2:0]}. They are kept separate
// and named here to match QL_DSP4's own parameter names, to make the techmap a
// straight pass-through, and to stay self-documenting in the BLIF; that packing
// is then one documented rule for the FASM side.
(* blackbox *)
module QL_DSP4_RSS (ACC_IN, ACC_OUT);
    // One combined configuration word. The order is NOT a synthesis choice: it
    // is the packing the physical macro already defines (see the note above),
    //
    //   mode = {SATURATE, SHIFT[5:0], ROUND[2:0]}
    //   MODE_BITS[2:0] ROUND   MODE_BITS[8:3] SHIFT   MODE_BITS[9] SATURATE
    //
    // and openfpga.xml already reserves exactly ten bits for this cell
    // (mode_bits="0000000000" on
    //  dsp.dsp_wrapper[dsp4_logical].dsp.dsp_core.inreg_cell.rss_cell.QL_DSP4_RSS).
    // DETAILED_SPEC.md Sec. 1.4 gives the same widths: ROUND 3, SHIFT 6,
    // SATURATE 1.
    parameter [9:0] MODE_BITS = 10'b0;

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

// KN pipeline register: carries the multiplier's dropped-carry flag alongside
// the M / MV partial-product banks so the X-mux pad stays aligned under MREG.
(* blackbox *)
module QL_DSP4_MK_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule

// The single carry-out bank. dsp4_top.v gates it with COUTREG and taps CCOUT
// off COUT[3] ("CCOUT is a tap of COUT[3], so the single carry-out register
// bank (COUTREG) serves both outputs"), so this one cell serves both COUT and
// the carry cascade.
//
// There were once QL_DSP4_CCO_DFFR and QL_DSP4_SCO_DFFR blackboxes here for a
// separate carry / sign cascade register. They were removed: no such register
// exists in the hardware (there is no CCOUTREG parameter anywhere, and
// SIGNCOUT is unregistered -- `assign SIGNCOUT = p_acc[49]`), they had no VPR
// model behind them, and the techmap never instantiated them. Confirmed with
// the arch owner before deletion.
(* blackbox *)
module QL_DSP4_CO_DFFR (D, R, clk, Q);
    input  wire D;
    input  wire R;
    (* clkbuf_sink *) input wire clk;
    output wire Q;
endmodule
