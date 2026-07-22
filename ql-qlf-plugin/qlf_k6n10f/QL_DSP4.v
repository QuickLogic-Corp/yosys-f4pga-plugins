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
// QL_DSP4 - generic monolithic DSP-V4 base cell (Phase 1).
//
// This is the primitive emitted by the `ql_dspv4` synthesis pass. It exposes the
// DSP-V4 static configuration as *parameters* (the "config word" of the Phase-1
// requirements doc, Appendix A) while data / cascade / clock / clock-enable /
// reset remain ports. That mirrors the V2 `QL_DSPV2` MODE_BITS split and matches
// the VPR operating model (`vpr_models.yaml` `QL_DSP4`), whose port list carries
// no OPMODE/ALUMODE/... - those are configuration.
//
// The behaviour is defined by the canonical DSP-V4 model `dsp4_top` in
// dspv4_sim.v (RTL is the single source of truth). This wrapper drives the
// dsp4_top configuration *input ports* from the QL_DSP4 *parameters* so the two
// stay bit-identical. Read with `-lib -specify` the module is treated as a
// black box (interface only); the body is used for functional/equivalence
// simulation.

module QL_DSP4 #(
    parameter [8:0] OPMODE      = 9'b000000101,  // W[8:7] Z[6:4] Y[3:2] X[1:0]
    parameter [1:0] ALUMODE     = 2'b00,         // 00 add, 11 sub, 01 rsub, 10 not
    parameter [4:0] INMODE      = 5'b00000,
    parameter [2:0] CARRYINSEL  = 3'b000,
    parameter [1:0] USE_SIMD    = 2'b00,
    parameter       AREG0       = 1'b0,
    parameter       AREG1       = 1'b0,
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
    input  wire        ARSTN,   // async, active-low
    input  wire        RSTN,    // sync,  active-low
    input  wire        ACCRSTN  // accumulator reset, synchronous, active-low
);

    dsp4_top u_dsp4 (
        .A          (A),
        .B          (B),
        .C          (C),
        .D          (D),
        .CIN        (CIN),
        .ACIN       (ACIN),
        .BCIN       (BCIN),
        .PCIN       (PCIN),
        .CCIN       (CCIN),
        .SIGNCIN    (SIGNCIN),
        .P          (P),
        .ACOUT      (ACOUT),
        .BCOUT      (BCOUT),
        .PCOUT      (PCOUT),
        .CCOUT      (CCOUT),
        .SIGNCOUT   (SIGNCOUT),
        .COUT       (COUT),
        // static configuration driven from parameters
        .OPMODE     (OPMODE),
        .ALUMODE    (ALUMODE),
        .INMODE     (INMODE),
        .CARRYINSEL (CARRYINSEL),
        .USE_SIMD   (USE_SIMD),
        .AREG0      (AREG0),
        .AREG1      (AREG1),
        .BREG0      (BREG0),
        .BREG1      (BREG1),
        .A_COUT_SEL (A_COUT_SEL),
        .B_COUT_SEL (B_COUT_SEL),
        .CREG       (CREG),
        .DREG       (DREG),
        .ADREG      (ADREG),
        .MREG       (MREG),
        .PREG       (PREG),
        .COUTREG    (COUTREG),
        .A_IN_SEL   (A_IN_SEL),
        .B_IN_SEL   (B_IN_SEL),
        .AMULTSEL   (AMULTSEL),
        .BMULTSEL   (BMULTSEL),
        .PREADDINSEL(PREADDINSEL),
        .USE_RSS    (USE_RSS),
        .ROUND      (ROUND),
        .SHIFT      (SHIFT),
        .SATURATE   (SATURATE),
        // clocking
        .CLK        (CLK),
        .CEA        (CEA),
        .CEB        (CEB),
        .CEC        (CEC),
        .CED        (CED),
        .CEP        (CEP),
        .ARSTN      (ARSTN),
        .RSTN       (RSTN),
        .ACCRSTN    (ACCRSTN)
    );

endmodule
