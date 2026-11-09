// An operand whose top bits repeat. The pass peels an extension off each
// operand so the register walk can see the flop behind it, and the DSP puts
// the extension back at the port width. Repeated top bits are an extension
// only on a signed operand. On an unsigned one they are part of the value:
// {a[15], a} is a + 65536 * a[15], and the DSP must multiply all of it.
//
// The pass peels three operands: the multiply's two sides and the
// pre-adder's D input. One design puts the repeated bit on each.
//
//   ona   {a[15], a} * b, unsigned: MULT, the repeated bit on the A side
//   two   {a[15], a[15], a} * b, unsigned: MULT, two copies
//   onb   b * {a[15], a} with a 20-bit b, unsigned: MULT. b is too wide for
//         the B side, so the operand with the repeated bit takes it
//   ond   ({d[15], d} + a) * b, unsigned: PREADD_A_MULT_B, the repeated
//         bit on the pre-adder's D input
module dspv4_operand_ext_ona (input [15:0] a, input [15:0] b, output [32:0] p);
  wire [16:0] a_ext = {a[15], a};
  assign p = a_ext * b;
endmodule

module dspv4_operand_ext_two (input [15:0] a, input [15:0] b, output [33:0] p);
  wire [17:0] a_ext = {a[15], a[15], a};
  assign p = a_ext * b;
endmodule

module dspv4_operand_ext_onb (input [15:0] a, input [19:0] b, output [36:0] p);
  wire [16:0] a_ext = {a[15], a};
  assign p = b * a_ext;
endmodule

module dspv4_operand_ext_ond (input [15:0] d, input [7:0] a, input [15:0] b, output [34:0] p);
  wire [16:0] d_ext = {d[15], d};
  assign p = (d_ext + a) * b;
endmodule
