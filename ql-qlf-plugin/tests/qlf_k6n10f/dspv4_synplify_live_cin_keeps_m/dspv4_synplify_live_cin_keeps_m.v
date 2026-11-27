// The other side of dspv4_synplify_gnd_cin_folds: the same lone-MREG multiply
// with a carry-in that is a real signal. The fold stores the carry-in with the
// product, so P would see it a cycle late. The real M banks must stay.
//
// Turning GND and VCC cells into constants early must not make a live pin look
// constant. The reset pins are tied through a VCC cell as in the twin, so the
// only difference between the two designs is the carry-in.
(* blackbox *) module VCC(output P); endmodule

module dspv4_synplify_live_cin_keeps_m (input clk, input cin, input [15:0] a, input [15:0] b, output [63:0] p);
  wire vcc;
  VCC tie_vcc (.P(vcc));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .MREG(1'b1)) u (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(cin),
    .RSTN(vcc), .ACCRSTN(vcc), .ARSTN(vcc),
    .CEA(vcc), .CEB(vcc), .CEC(vcc), .CED(vcc), .CEP(vcc), .P(p));
endmodule
