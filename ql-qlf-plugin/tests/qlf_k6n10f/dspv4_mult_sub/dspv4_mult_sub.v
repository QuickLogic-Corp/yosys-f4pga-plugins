// C - A*B is MULT_SUB_C, the ALU's subtract direction. The operand order is
// deliberate: A*B - C is the reverse-subtract direction and a different mode
// (MULT_RSUB_C, see dspv4_mult_rsub_c), so swapping these would still infer a
// DSP and still count the same cells while negating the result.
module dspv4_mult_sub (input signed [17:0] a, input signed [17:0] b,
                       input signed [35:0] c, output signed [35:0] p);
  assign p = c - a * b;
endmodule
