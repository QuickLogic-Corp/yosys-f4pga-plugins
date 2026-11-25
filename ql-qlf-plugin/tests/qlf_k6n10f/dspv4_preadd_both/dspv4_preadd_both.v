// Both multiply operands are pre-adder sums. The DSP has one pre-adder, so
// one of them stays in fabric -- the WIDER must be absorbed, because the sum
// left outside costs a carry chain proportional to its width.
//
// The two sums are deliberately different widths. One QL_DSP4_PREADD is the
// same count whichever side was taken, so the adder_carry left behind is the
// only evidence of which one the pass chose: the 8-bit sum leaves about 9,
// the 18-bit sum would leave about 19.
module dspv4_preadd_both (input signed [17:0] d, input signed [17:0] a,
                          input signed [7:0] e, input signed [7:0] b,
                          output signed [40:0] p);
  assign p = (d + a) * (e + b);
endmodule

// Two unsigned sums with equal operand widths, a difference on A and a sum on
// B. Neither is wider, so the RTL order decides and the difference is absorbed.
// An unsigned difference needs one result bit less than a sum; ranking by
// result width would wrongly make it the narrower one. Synthesised on its own,
// so the carry chain it leaves does not mix with the design above.
module dspv4_preadd_both_tie (input [15:0] d0, input [15:0] a0,
                              input [15:0] d1, input [15:0] a1,
                              output [16:0] p);
  wire [16:0] s0 = d0 - a0;
  wire [16:0] s1 = d1 + a1;
  assign p = s0 * s1;
endmodule
