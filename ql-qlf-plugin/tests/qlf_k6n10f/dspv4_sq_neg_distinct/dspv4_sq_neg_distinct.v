// The guard for REQ-B3: -(a * b) with two DIFFERENT operands must NOT be
// folded into the ALU.
//
// The hardware could obviously do it -- 0 - M is the same ALU operation
// whatever fed the multiplier -- but the mode table has no ALUMODE=11 word
// with AMULTSEL and BMULTSEL clear. The only negating words are SQ_A_NEG and
// SQ_B_NEG, and both route AD to BOTH multiplier ports, which is only correct
// when the two ports carry the same value.
//
// So this must come out as a plain MULT with the negate still in fabric. The
// bad outcome is not a missing optimisation: it is emitting SQ_A_NEG here,
// which would feed a to both ports and quietly compute -(a * a).
module dspv4_sq_neg_distinct (input signed [15:0] a, input signed [15:0] b,
                              output signed [33:0] p);
  assign p = -(a * b);
endmodule
