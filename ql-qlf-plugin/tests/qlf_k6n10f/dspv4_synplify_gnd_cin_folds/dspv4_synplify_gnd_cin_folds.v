// What Synplify hands over for a lone-MREG multiply: a QL_DSP4 whose tied-off
// pins come from GND and VCC cells, not from constants. The carry-in on the GND
// cell is a constant 0 in every way that matters, so the multiply must fold its
// M register onto the accumulator register, as it does with a literal 0.
//
// The techmap decides on a pin as it maps, and the GND and VCC cells used to be
// turned into constants only later, in the BRAM map. A carry-in on a GND cell
// looked live and the fold never fired (aurora2 #2970).
(* blackbox *) module GND(output G); endmodule
(* blackbox *) module VCC(output P); endmodule

module dspv4_synplify_gnd_cin_folds (input clk, input [15:0] a, input [15:0] b, output [63:0] p);
  wire gnd, vcc;
  GND tie_gnd (.G(gnd));
  VCC tie_vcc (.P(vcc));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .MREG(1'b1)) u (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(gnd),
    .RSTN(vcc), .ACCRSTN(vcc), .ARSTN(vcc),
    .CEA(vcc), .CEB(vcc), .CEC(vcc), .CED(vcc), .CEP(vcc), .P(p));
endmodule
