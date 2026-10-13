// An operand register whose Q is also a module output.
//
// The register goes into the A bank, and the port still needs the fabric
// flop: a bank is internal to the DSP and nothing outside can read it. So the
// flop is copied rather than moved -- one A2 bank in the DSP and the 18
// design flops still standing to drive q. Moving it left q undriven.
module dspv4_mult_regin_port (input clk,
                              input signed [17:0] a, input signed [17:0] b,
                              output signed [35:0] p,
                              output signed [17:0] q);
  reg signed [17:0] a_reg;
  always @(posedge clk) a_reg <= a;
  assign p = a_reg * b;
  assign q = a_reg;
endmodule
