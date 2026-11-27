// Four QL_DSP4 cells, each breaking one rule the techmap enforces today
// (UNSUPPORTED in dsp4_logical_map.v). The techmap leaves a refused cell as a
// QL_DSP4 and says nothing, so synthesis has to stop on the leftover cells. The
// error lists all of them, and the Makefile checks that each cell is named.
// dspv4_techmap_twin_maps has the same four cells with the rule satisfied.
//
//   u_w       reserved W encoding (W_SEL = 10)
//   u_y       reserved Y encoding (Y_SEL = 10)
//   u_carry   CARRYINSEL = 001, which no carry source uses
//   u_carryp  CARRYINSEL = 100 with P fed back (Z = P)
module dspv4_techmap_refused_stops (input clk, input [15:0] a, input [15:0] b,
                  output [63:0] p_w,
                  output [63:0] p_y,
                  output [63:0] p_carry,
                  output [63:0] p_carryp);
  QL_DSP4 #(.OPMODE(9'b10_000_01_01)) u_w (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_w));
  QL_DSP4 #(.OPMODE(9'b00_000_10_01)) u_y (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_y));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .CARRYINSEL(3'b001)) u_carry (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_carry));
  QL_DSP4 #(.OPMODE(9'b00_010_01_01), .PREG(1'b1), .CARRYINSEL(3'b100)) u_carryp (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_carryp));
endmodule
