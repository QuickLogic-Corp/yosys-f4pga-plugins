// The twin of dspv4_techmap_refused_drc: cells with the design rule satisfied.
// Each must map to leaf cells and leave no QL_DSP4 behind.
//
//   u_simd     SIMD with one operand (A:B) and a carry-in from CIN: rules 1 to 4
//   u_uv       X = U with Y = V
//   u_z        a Z encoding that exists (Z_SEL = 011)
//   u_maccext  MACC_EXT with ALUMODE = 00
//   u_ce3      three clock-enable nets on the registers in use
module dspv4_techmap_twin_drc_maps (input clk, input [15:0] a, input [15:0] b, input ea, input eb, input ec,
                                    output [49:0] p_simd,
                                    output [49:0] p_uv,
                                    output [49:0] p_z,
                                    output [49:0] p_maccext,
                                    output [49:0] p_ce3);
  QL_DSP4 #(.OPMODE(9'b00_011_00_11), .USE_SIMD(2'b01)) u_simd (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_simd));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01)) u_uv (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_uv));
  QL_DSP4 #(.OPMODE(9'b00_011_01_01)) u_z (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_z));
  QL_DSP4 #(.OPMODE(9'b00_100_01_01), .ALUMODE(2'b00)) u_maccext (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_maccext));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .AREG1(1'b1), .BREG1(1'b1), .CREG(1'b1)) u_ce3 (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(ea), .CEB(eb), .CEC(ec), .CED(1'b1), .CEP(1'b1), .P(p_ce3));
endmodule
