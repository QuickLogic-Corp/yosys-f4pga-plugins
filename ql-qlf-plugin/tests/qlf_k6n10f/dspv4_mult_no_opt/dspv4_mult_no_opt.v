// Same multiply as dspv4_mult, synthesised with -no_opt. Signed operands: the
// DSP multiplier is signed, so an unsigned 18-bit value is left soft by design.
module dspv4_mult_no_opt (input signed [17:0] a, input signed [17:0] b,
                          output signed [35:0] p);
  assign p = a * b;
endmodule
