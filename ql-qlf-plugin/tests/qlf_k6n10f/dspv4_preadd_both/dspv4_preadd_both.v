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
