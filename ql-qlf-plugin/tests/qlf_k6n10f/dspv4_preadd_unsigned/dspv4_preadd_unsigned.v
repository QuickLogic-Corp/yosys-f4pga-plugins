// The adder is unsigned and the multiply reads its result as signed. Same
// bits, different number, whenever bit 16 is set. Must be refused.
//
// With the guard removed: 968 of 2000 random vectors wrong.
module dspv4_preadd_unsigned (input [15:0] a, input [15:0] b,
                              input signed [15:0] c,
                              output signed [33:0] y);
  wire [16:0] s = a + b;
  assign y = $signed(s) * c;
endmodule
