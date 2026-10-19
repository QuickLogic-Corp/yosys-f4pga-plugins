// M2.4 -- an operand of the pre-adder is also the other multiply operand.
//
// (D + A) * A reads `a` twice: once into the pre-adder, once straight into
// the multiplier. That is not the squaring shape, which is one adder feeding
// BOTH multiply ports and is refused -- see dspv4_preadd_square. Here only one
// port comes from the adder, so the fold is safe and the shared operand just
// fans out to two places inside the DSP.
module dspv4_preadd_shared (input signed [15:0] d, input signed [15:0] a,
                            output signed [33:0] p);
  assign p = (d + a) * a;
endmodule
