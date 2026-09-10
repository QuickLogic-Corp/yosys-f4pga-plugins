// One operand register feeding three multiplies.
//
// The register bank is per-DSP, so a shared operand register has to be COPIED
// into each DSP's own bank -- moving it into one would strip the value from the
// other two. The fan-out guard used to refuse the whole shape, leaving the
// register in fabric; Synplify duplicates it, which is free because the bank
// exists in the DSP tile whether or not it is used.
module dspv4_mult_shared_operand (input clk, input rst,
                                  input signed [17:0] a,
                                  input signed [17:0] b1, b2, b3,
                                  output signed [35:0] p1, p2, p3);
  reg signed [17:0] a_reg;
  always @(posedge clk)
    if (rst) a_reg <= 0; else a_reg <= a;
  assign p1 = a_reg * b1;
  assign p2 = a_reg * b2;
  assign p3 = a_reg * b3;
endmodule
