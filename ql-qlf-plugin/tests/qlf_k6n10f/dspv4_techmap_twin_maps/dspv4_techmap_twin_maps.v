// The twin of dspv4_techmap_refused_stops: the same four cells with the rule
// satisfied. Each must map to leaf cells and leave no QL_DSP4 behind.
//
//   u_w       W = 00 instead of the reserved 10
//   u_y       Y = V, with X = U (X = U alone is refused) instead of the reserved 10
//   u_carry   CARRYINSEL = 010, the cascaded carry, instead of 001
//   u_carryp  CARRYINSEL = 100 with no P feedback
module dspv4_techmap_twin_maps (input clk, input [15:0] a, input [15:0] b,
                  output [63:0] p_w,
                  output [63:0] p_y,
                  output [63:0] p_carry,
                  output [63:0] p_carryp);
  QL_DSP4 #(.OPMODE(9'b00_000_01_01)) u_w (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_w));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01)) u_y (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_y));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .CARRYINSEL(3'b010)) u_carry (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .CCIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_carry));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .CARRYINSEL(3'b100)) u_carryp (.CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_carryp));
endmodule
