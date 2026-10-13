// A truncated product through a product register, added at its own width:
// exact in the DSP, 0 of 2000 cycles wrong, and the M register must still be
// absorbed together with the adder.
module dspv4_trunc_narrow_mreg (input clk, input [16:0] a, input [17:0] b,
                                input [16:0] c, output [16:0] p);
  wire [16:0] m = a * b;
  reg [16:0] mr;
  always @(posedge clk) mr <= m;
  assign p = mr + c;
endmodule
