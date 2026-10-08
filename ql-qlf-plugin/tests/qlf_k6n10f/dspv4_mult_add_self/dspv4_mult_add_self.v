// One adder reading the product on BOTH of its operands.
//
// nusers counts reader CELLS, so this product has nusers 2 -- driven once, read
// by one cell -- and every fanout guard in ql-dspv4.pmg passes. The pass then
// absorbed the multiply and took C from the adder's "other" operand, which is
// the product it had just deleted: the netlist came out as a MULT_ADD_C whose
// ALU Z input was tied to 64'hxxxxxxxxxxxxxxxx. `check` reported no problems and
// the design packed and routed, so nothing downstream noticed.
//
// The multiply still belongs in a DSP; only the addition has to stay in fabric.
module dspv4_mult_add_self (input signed [17:0] a, input signed [17:0] b,
                            output signed [36:0] p);
  wire signed [35:0] m = a * b;
  assign p = m + m;
endmodule
