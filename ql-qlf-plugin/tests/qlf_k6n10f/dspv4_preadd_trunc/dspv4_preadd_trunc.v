// The adder declares a result one bit too narrow to hold its own sum, so the
// RTL wraps at 16 bits. The DSP pre-adder is wider and would not. Must be
// refused.
//
// With the guard removed: 496 of 2000 random vectors wrong, whenever a + b
// overflows 16 bits.
module dspv4_preadd_trunc (input signed [15:0] a, input signed [15:0] b,
                           input signed [15:0] c,
                           output signed [31:0] y);
  wire signed [15:0] s = a + b;
  assign y = s * c;
endmodule
