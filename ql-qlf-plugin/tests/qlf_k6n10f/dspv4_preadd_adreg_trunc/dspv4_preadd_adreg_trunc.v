// Registered pre-adder sum that the multiply only partly reads.
//
// The AD flop makes the guard chain look at the flop's D, which says what the
// adder produced but not how much of it the multiply takes. Here the sum is 17
// bits and the multiply reads 16, so the RTL wraps at 16 where the DSP's
// pre-adder would carry on. Without -no_opt, wreduce narrows the adder first
// and a different guard catches it; this test must refuse it either way.
module dspv4_preadd_adreg_trunc (input clk, input [15:0] d, input [15:0] a,
                                 input [17:0] b, output [33:0] p);
  reg [16:0] ad;
  always @(posedge clk) ad <= d + a;
  assign p = ad[15:0] * b;
endmodule
