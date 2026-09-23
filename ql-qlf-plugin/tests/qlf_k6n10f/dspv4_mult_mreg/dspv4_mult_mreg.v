// A register between the multiply and the adder -- the DSP's M stage.
//
// This is the shape that had no home before MREG inference: the product is
// registered, then added combinationally, with no register on the result. The
// techmap used to fold a lone MREG onto the P register, which puts the ALU
// inside the registered path and so samples C a cycle early -- silently wrong.
// Now it gets the real M/MV/MK banks and the adder still fuses, so nothing is
// left in fabric.
module dspv4_mult_mreg (input clk,
                        input signed [17:0] a, input signed [17:0] b,
                        input signed [35:0] c,
                        output signed [36:0] p);
  reg signed [35:0] prod;
  always @(posedge clk) prod <= a * b;
  assign p = c + prod;
endmodule
