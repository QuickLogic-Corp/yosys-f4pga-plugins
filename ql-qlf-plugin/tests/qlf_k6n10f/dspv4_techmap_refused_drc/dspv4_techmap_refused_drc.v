// Eight QL_DSP4 cells, each breaking one design rule that the DSP-V4 techmap
// enforces (DRC_FAIL in dsp4_logical_map.v, openphy-turnkey-flow #2173). The
// techmap leaves a refused cell as a QL_DSP4, synthesis stops on it, and
// ql_dsp4_explain names the rule. The Makefile checks each cell's message.
// dspv4_techmap_twin_drc_maps has cells with the rule satisfied.
//
//   u_simd11     USE_SIMD = 11
//   u_simdwxy    SIMD with the multiplier, which counts as two of W, X and Y
//   u_simdrss    SIMD with USE_RSS
//   u_simdcarry  SIMD with the carry from CCIN
//   u_uwithoutv  X = U without Y = V
//   u_zres       reserved Z encoding (Z_SEL = 111)
//   u_maccext    MACC_EXT (Z_SEL = 100) with ALUMODE = 01
//   u_ce4        four clock-enable nets on the registers in use
module dspv4_techmap_refused_drc (input clk, input [15:0] a, input [15:0] b, input ea, input eb, input ec, input ep,
                                  output [49:0] p_simd11,
                                  output [49:0] p_simdwxy,
                                  output [49:0] p_simdrss,
                                  output [49:0] p_simdcarry,
                                  output [49:0] p_uwithoutv,
                                  output [49:0] p_zres,
                                  output [49:0] p_maccext,
                                  output [49:0] p_ce4);
  QL_DSP4 #(.OPMODE(9'b00_011_00_00), .USE_SIMD(2'b11)) u_simd11 (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_simd11));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .USE_SIMD(2'b01)) u_simdwxy (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_simdwxy));
  QL_DSP4 #(.OPMODE(9'b00_011_00_00), .USE_SIMD(2'b01), .USE_RSS(1'b1)) u_simdrss (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_simdrss));
  QL_DSP4 #(.OPMODE(9'b00_011_00_00), .USE_SIMD(2'b01), .CARRYINSEL(3'b010)) u_simdcarry (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .CCIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_simdcarry));
  QL_DSP4 #(.OPMODE(9'b00_000_00_01)) u_uwithoutv (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_uwithoutv));
  QL_DSP4 #(.OPMODE(9'b00_111_01_01)) u_zres (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_zres));
  QL_DSP4 #(.OPMODE(9'b00_100_01_01), .ALUMODE(2'b01)) u_maccext (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_maccext));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .AREG1(1'b1), .BREG1(1'b1), .CREG(1'b1), .PREG(1'b1)) u_ce4 (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(ea), .CEB(eb), .CEC(ec), .CED(1'b1), .CEP(ep), .P(p_ce4));
endmodule
