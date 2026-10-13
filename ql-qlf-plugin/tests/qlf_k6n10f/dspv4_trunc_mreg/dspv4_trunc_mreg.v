// A truncated product through a product register, then added at full width.
// The M bank registers the multiplier's full output, so MULT_ADD_C with an M
// register was wrong on 2000 of 2000 cycles. The register itself still fits in
// the DSP: without the adder it is the result register, and P holds it.
module dspv4_trunc_mreg (input clk, input [16:0] a, input [17:0] b,
                         input [34:0] c, output [34:0] p);
  wire [16:0] m = a * b;
  reg [16:0] mr;
  always @(posedge clk) mr <= m;
  assign p = mr + c;
endmodule
