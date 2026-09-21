// A negated square: -(x * x). Phase 4, REQ-B3, mode SQ_A_NEG.
//
// The DSP's ALU computes Z - (X + Y + CIN). SQ_A_NEG sets Z to zero and puts
// the product on X:Y with ALUMODE=11, so P comes out as -M for free -- the
// negate costs nothing the multiply was not already paying.
//
// Left in fabric it is not cheap: a 34-bit negate lowers to 34 adder_carry and
// 33 LUTs, so this one expression was 70 cells before the mode was inferred
// and is 3 after.
//
// x is signed because the multiplier is Baugh-Wooley signed; an unsigned
// operand costs a bit of port capacity. The negate itself works either way --
// -M mod 2^50 truncated to any narrower width is still -M mod that width.
module dspv4_sq_neg (input signed [15:0] x, output signed [33:0] p);
  assign p = -(x * x);
endmodule
