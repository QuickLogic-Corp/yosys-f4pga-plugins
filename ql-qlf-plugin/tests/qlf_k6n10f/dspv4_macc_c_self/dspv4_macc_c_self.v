// p <= (a * b + p) + (a * b + p): the C adder reads the inner sum twice.
//
// nusers counts cells, so the sum looks sole-read and the double-read guard
// is what refuses the fusion. The fallback is the same as in
// dspv4_macc_c_reader -- MULT_ADD_C with p on the C port -- reached through a
// different refusal, with the same requirement: p is a module output, so its
// register is copied into CREG, not moved.
module dspv4_macc_c_self (input clk, input rst,
                          input signed [17:0] a, input signed [17:0] b,
                          output reg signed [49:0] p);
  wire signed [49:0] s = a * b + p;
  always @(posedge clk)
    if (rst) p <= 0; else p <= s + s;
endmodule
