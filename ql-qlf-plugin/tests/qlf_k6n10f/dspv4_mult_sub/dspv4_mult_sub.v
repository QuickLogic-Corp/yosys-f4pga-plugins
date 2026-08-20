// C - A*B is MULT_SUB_C. A*B - C has no multiply-form control word and would
// legitimately stay soft, so the operand order here is deliberate.
module dspv4_mult_sub (input signed [17:0] a, input signed [17:0] b,
                       input signed [35:0] c, output signed [35:0] p);
  assign p = c - a * b;
endmodule
