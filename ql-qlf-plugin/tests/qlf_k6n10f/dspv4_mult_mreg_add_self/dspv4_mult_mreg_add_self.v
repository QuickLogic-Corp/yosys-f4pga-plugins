// The same adder-reads-the-product-twice shape, with a register in between.
//
// This one did not produce a wrong netlist, it aborted. The M register is the
// only reader of the product and the adder is the only reader of the M
// register, so both nusers guards pass. The C-operand walk then went looking
// for registers behind C -- which is that same M register -- found one reader,
// and claimed it as a SHARED copy, i.e. one to leave standing for its other
// readers. pmgen had already marked the very same cell for autoremove, so by
// the time the userless sweep read its Q port the cell was freed:
//
//   terminate called after throwing an instance of 'std::out_of_range'
//     what():  dict::at()
//
// Refusing the fusion leaves the product register free to go in the DSP's P
// bank instead, which is where the correct netlist puts it.
module dspv4_mult_mreg_add_self (input clk,
                                 input signed [17:0] a, input signed [17:0] b,
                                 output signed [36:0] p);
  reg signed [35:0] m;
  assign p = m + m;
  always @(posedge clk) m <= a * b;
endmodule
