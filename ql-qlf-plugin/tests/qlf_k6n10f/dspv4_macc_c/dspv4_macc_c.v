// Multiply-accumulate with a C addend: p <= (a * b + p) + c.
//
// The whole chain folds as MULT_ACC_C -- product, feedback and C in one DSP,
// nothing left in fabric. This is the baseline for dspv4_macc_c_reader and
// dspv4_macc_c_self, which take the same chain and give the inner sum a
// second reader: the fusion is refused there, and this test pins that the
// refusal is not the default.
module dspv4_macc_c (input clk, input rst,
                     input signed [17:0] a, input signed [17:0] b,
                     input signed [33:0] c,
                     output reg signed [49:0] p);
  wire signed [49:0] s = a * b + p;
  always @(posedge clk)
    if (rst) p <= 0; else p <= s + c;
endmodule
