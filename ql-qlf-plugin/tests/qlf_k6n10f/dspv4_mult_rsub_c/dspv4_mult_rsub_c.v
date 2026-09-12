// A*B - C, the reverse-subtract direction on the C port.
//
// The mirror of dspv4_mult_sub (C - A*B). The spreadsheet paired the
// reverse-subtract direction with the A:B bus only (RSUB_AB_C), never with the
// multiplier path, so this shape had no control word and stayed soft --
// MULT_RSUB_C supplies it.
module dspv4_mult_rsub_c (input signed [17:0] a, input signed [17:0] b,
                          input signed [35:0] c, output signed [35:0] p);
  assign p = a * b - c;
endmodule
