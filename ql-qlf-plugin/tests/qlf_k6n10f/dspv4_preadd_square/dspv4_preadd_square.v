// One adder feeding both multiply operands. That is the squaring shape, which
// needs AMULTSEL and BMULTSEL set together, and belongs to the squaring phase.
//
// Absorbing it here would rewrite one multiplier port and leave the other
// reading a cell that no longer exists -- every output bit X. Must be refused
// and left in fabric.
module dspv4_preadd_square (input signed [15:0] a, input signed [15:0] b,
                            output signed [33:0] y);
  wire signed [16:0] s = a + b;
  assign y = s * s;
endmodule
