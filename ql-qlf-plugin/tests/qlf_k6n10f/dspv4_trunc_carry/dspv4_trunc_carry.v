// The adder's operands are both 17 bits, so the adder reads nothing above the
// truncated product -- but the sum keeps its carry, and that one bit is where
// the full product shows through: 1523 of 3000 vectors wrong. A guard that
// only compares the adder's operand width against the product misses this
// shape; the width that matters is the result's.
module dspv4_trunc_carry (input [16:0] a, input [17:0] b, input [16:0] c,
                          output [17:0] p);
  wire [16:0] m = a * b;
  assign p = m + c;
endmodule
