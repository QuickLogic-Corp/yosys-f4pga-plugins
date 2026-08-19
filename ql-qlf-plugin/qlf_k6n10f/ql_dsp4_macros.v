// ql_dsp4_macros.v -- GENERATED FILE, DO NOT EDIT BY HAND.
//
// Regenerate:  aurora2/scripts/dspv4/gen_dspv4_macros.py
// Check:       aurora2/scripts/dspv4/gen_dspv4_macros.py --check
//
// Instantiable wrappers around QL_DSP4, one per DSP-V4 building block. Each is a
// real module, NOT a blackbox: it elaborates into a QL_DSP4 cell with its
// parameters already set and lowers through dsp4_logical_map.v, so it exercises
// the same path Yosys inference, Synplify and the V2 bridge all converge on.
//
// The set is deliberately small (IN-13): a macro exists only for something the
// flow cannot infer, or that the hardware team needs in order to verify a block.
// Nothing is unreachable without one -- QL_DSP4 is directly instantiable.

// ---------------------------------------------------------------------------
// RSS block (round / shift / saturate)
//
// RSS is parameter-controlled, not a mode. This passes C through the ALU so the only interesting cell is QL_DSP4_RSS.
//
// Lowers to: QL_DSP4_RSS, QL_DSP4_ALU_ADD, QL_DSP4_ACC_DFFRE
// ---------------------------------------------------------------------------
module ql_dsp4_rss #(
    parameter [2:0] ROUND = 3'b000,
    parameter [5:0] SHIFT = 6'd0,
    parameter SATURATE = 1'b0
) (
    input  wire        CLK,
    input  wire        ARSTN,
    input  wire        CEP,
    input  wire [49:0] C,
    output wire [49:0] P
);
  QL_DSP4 #(
      .OPMODE(9'b000110000), .ALUMODE(2'b00), .PREG(1'b1), .USE_RSS(1'b1), .ROUND(ROUND), .SHIFT(SHIFT), .SATURATE(SATURATE)
  ) u_dsp (
      .A(32'd0), .B(18'd0), .C(C), .D(27'd0),
      .CIN(1'b0), .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0),
      .SIGNCIN(1'b0),
      .P(P), .ACOUT(), .BCOUT(), .PCOUT(),
      .CCOUT(), .SIGNCOUT(), .COUT(),
      .CLK(CLK), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1),
      .CEP(CEP), .ARSTN(ARSTN), .RSTN(1'b1), .ACCRSTN(1'b1)
  );
endmodule

// ---------------------------------------------------------------------------
// ALU block (all four ALUMODE variants)
//
// A:B + C with the multiplier bypassed, so exactly one QL_DSP4_ALU_* leaf is produced and nothing else. ALUMODE is a parameter: 00 add, 01 reverse-subtract, 10 not-sum, 11 subtract.
//
// Lowers to: one of QL_DSP4_ALU_{ADD,REV_SUB,NOT_SUM,SUB}
// ---------------------------------------------------------------------------
module ql_dsp4_alu #(
    parameter [1:0] ALUMODE = 2'b00,
    parameter PREG = 1'b0
) (
    input  wire        CLK,
    input  wire        ARSTN,
    input  wire        CEP,
    input  wire [31:0] A,
    input  wire [17:0] B,
    input  wire [49:0] C,
    output wire [49:0] P
);
  QL_DSP4 #(
      .OPMODE(9'b000110011), .ALUMODE(ALUMODE), .ALUMODE(ALUMODE), .PREG(PREG)
  ) u_dsp (
      .A(A), .B(B), .C(C), .D(27'd0),
      .CIN(1'b0), .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0),
      .SIGNCIN(1'b0),
      .P(P), .ACOUT(), .BCOUT(), .PCOUT(),
      .CCOUT(), .SIGNCOUT(), .COUT(),
      .CLK(CLK), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1),
      .CEP(CEP), .ARSTN(ARSTN), .RSTN(1'b1), .ACCRSTN(1'b1)
  );
endmodule

// ---------------------------------------------------------------------------
// Pipelined multiplier (M / MV / MK register banks)
//
// MULT with MREG set. The techmap folds MREG to require PREG, and the product still leaves through the ALU and accumulator, so those appear too -- there is no datapath to the multiplier that avoids them.
//
// Lowers to: QL_DSP4_MULT, QL_DSP4_M_DFFR x50, QL_DSP4_MV_DFFR x43, QL_DSP4_MK_DFFR x1, QL_DSP4_ALU_ADD, QL_DSP4_ACC_DFFRE
// ---------------------------------------------------------------------------
module ql_dsp4_mult_pipelined (
    input  wire        CLK,
    input  wire        ARSTN,
    input  wire        CEP,
    input  wire [31:0] A,
    input  wire [17:0] B,
    output wire [49:0] P
);
  QL_DSP4 #(
      .OPMODE(9'b000000101), .ALUMODE(2'b00), .MREG(1'b1), .PREG(1'b1)
  ) u_dsp (
      .A(A), .B(B), .C(50'd0), .D(27'd0),
      .CIN(1'b0), .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0),
      .SIGNCIN(1'b0),
      .P(P), .ACOUT(), .BCOUT(), .PCOUT(),
      .CCOUT(), .SIGNCOUT(), .COUT(),
      .CLK(CLK), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1),
      .CEP(CEP), .ARSTN(ARSTN), .RSTN(1'b1), .ACCRSTN(1'b1)
  );
endmodule
