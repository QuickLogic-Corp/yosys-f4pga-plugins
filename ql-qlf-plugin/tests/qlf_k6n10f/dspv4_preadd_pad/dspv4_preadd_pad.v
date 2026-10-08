// The multiply operand is wider than the sum and the extra bit is a constant
// zero, not a sign extension. The RTL value is therefore never negative; the
// DSP would keep the sum signed. Must be refused.
//
// With the guard removed: 1005 of 2000 random vectors wrong, exactly the ones
// where the sum is negative.
module dspv4_preadd_pad (input signed [15:0] a, input signed [15:0] b,
                         input signed [15:0] c,
                         output signed [34:0] y);
  wire signed [16:0] s = a + b;
  assign y = $signed({1'b0, s}) * c;
endmodule
