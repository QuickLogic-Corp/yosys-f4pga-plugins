// The chain of dspv4_macc_c with a second reader of the inner sum.
//
// Absorbing the C adder would make `s` internal to the DSP, so the pass
// refuses MULT_ACC_C and falls back to MULT_ADD_C: a * b + p with p on the C
// port and the `+ c` adder in fabric. p's register then sits on the C operand
// and is copied into CREG. It has to be a copy: p is a module output, and
// moving the flop left the port with no driver -- `assign p = 50'hx` in the
// netlist, with `check -assert` reporting nothing.
module dspv4_macc_c_reader (input clk, input rst,
                            input signed [17:0] a, input signed [17:0] b,
                            input signed [33:0] c,
                            output reg signed [49:0] p,
                            output reg signed [49:0] q);
  wire signed [49:0] s = a * b + p;
  always @(posedge clk) begin
    if (rst) p <= 0; else p <= s + c;
    q <= s;
  end
endmodule
