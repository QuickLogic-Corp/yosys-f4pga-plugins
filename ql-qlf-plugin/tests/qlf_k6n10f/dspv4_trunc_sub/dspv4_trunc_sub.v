// Same truncated product as dspv4_trunc_add, subtracted from C. MULT_SUB_C
// has the same ALU behind the same untruncated multiplier, and was wrong on
// 3000 of 3000 vectors.
module dspv4_trunc_sub (input [16:0] a, input [17:0] b, input [34:0] c,
                        output [34:0] p);
  wire [16:0] m = a * b;
  assign p = c - m;
endmodule
