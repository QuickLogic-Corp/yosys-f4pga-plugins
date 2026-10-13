// Same truncated product, with C subtracted from it. MULT_RSUB_C was wrong on
// 3000 of 3000 vectors.
module dspv4_trunc_rsub (input [16:0] a, input [17:0] b, input [34:0] c,
                         output [34:0] p);
  wire [16:0] m = a * b;
  assign p = m - c;
endmodule
