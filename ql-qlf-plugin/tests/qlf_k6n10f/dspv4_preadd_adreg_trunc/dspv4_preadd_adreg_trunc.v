// Registered pre-adder sum that the multiply only partly reads.
//
// The AD flop makes the guard chain look at the flop's D, which says what the
// adder produced but not how much of it the multiply takes. Here the sum is 17
// bits and the multiply reads 16, so the RTL wraps at 16 where the DSP's
// pre-adder would carry on. Without -no_opt, wreduce narrows the adder first
// and a different guard catches it; this test must refuse it either way.
//
// ones_ad is the same shape with an unsigned all-ones constant:
// d + 16'hFFFF needs 17 bits, because the constant is large, not -1.
//
// sub_ad is an unsigned subtract in a 16-bit flop, read through its low 12
// bits. The RTL wraps at 12, the DSP's pre-adder goes negative, and the 14-bit
// product is past 12, so the two disagree whenever sub_d < sub_a. The 16-bit
// subtract is not the width that matters: the multiply reads 12 of it.
module dspv4_preadd_adreg_trunc (input clk, input [15:0] d, input [15:0] a,
                                 input [17:0] b, output [33:0] p,
                                 input [7:0] ones_d, input [19:0] ones_b,
                                 output [35:0] ones_p,
                                 input [7:0] sub_d, input [7:0] sub_a,
                                 input [7:0] sub_b, output [13:0] sub_p);
  reg [16:0] ad;
  always @(posedge clk) begin
    ad <= d + a;
  end
  assign p = ad[15:0] * b;

  reg [16:0] ones_ad;
  always @(posedge clk) begin
    ones_ad <= ones_d + 16'hFFFF;
  end
  assign ones_p = ones_ad[15:0] * ones_b;

  reg [15:0] sub_ad;
  always @(posedge clk) begin
    sub_ad <= sub_d - sub_a;
  end
  assign sub_p = sub_ad[11:0] * sub_b;
endmodule
