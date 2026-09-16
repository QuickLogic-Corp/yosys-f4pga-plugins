// The DSP's pre-adder: D + A feeds one multiplier port, so (d + a) * b is one
// cell rather than a fabric carry chain plus a DSP.
//
// Widths are chosen so the sum lands on the A path. d and a are 16-bit, so
// d + a needs 17 -- well inside AD's 32 bits on that path -- and b is 18-bit,
// which is exactly the other multiplier port. Putting the sum on the B path
// instead would truncate AD to 18 bits, which is why the pass proves the width
// before picking a mode rather than after.
//
// Operands are signed: the multiplier is Baugh-Wooley signed, so an unsigned
// operand costs a bit of port capacity and is left soft by design.
module dspv4_preadd_a (input signed [15:0] d, input signed [15:0] a,
                       input signed [17:0] b,
                       output signed [34:0] p);
  assign p = (d + a) * b;
endmodule
