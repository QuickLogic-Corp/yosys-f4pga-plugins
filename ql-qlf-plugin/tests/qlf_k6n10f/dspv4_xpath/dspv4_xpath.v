// Cross-path: the pre-adder's sum multiplies one of its own operands.
//
// A PREADD word with the shared operand on port A would put it on ports A and
// B. The XPATH words read it once. Where no XPATH word fits, a PREADD word
// still folds it with the shared operand on port D instead.
//
//   na    (d + a) * a, a 17-bit sum fits the 18-bit B side: XPATH_A
//   wd    a 26-bit d makes a 27-bit sum, which takes the 32-bit A side: XPATH_B
//   wide  a 28-bit d does not fit port D, so a goes there: PREADD_A_MULT_B
//   min   (a - d) * a. XPATH has no subtract word; a is the minuend, so it can
//         take port D: PREADD_A_SUB_B
//   wdr   wd with a registered. The B bank absorbs the register, and the empty
//         A port must not cost it: nothing stays in fabric. XPATH_B
//   uns   unsigned 17-bit operands. Their 18-bit sum needs 19 signed bits, too
//         many for the B side; a fits B: XPATH_B
//   minc  (a - d) * a + c. No XPATH word has an ALU term, but a is the minuend
//         and takes port D: PREADD_A_SUB_B_C
//   widec (d + a) * a + c with a 28-bit d: a takes port D: PREADD_A_MULT_B_C
module dspv4_xpath (
    input clk,
    input signed [15:0] na_d, input signed [15:0] na_a, output signed [33:0] na_p,
    input signed [25:0] wd_d, input signed [15:0] wd_a, output signed [42:0] wd_p,
    input signed [27:0] wide_d, input signed [15:0] wide_a, output signed [44:0] wide_p,
    input signed [15:0] min_d, input signed [15:0] min_a, output signed [33:0] min_p,
    input signed [25:0] wdr_d, input signed [15:0] wdr_a, output signed [42:0] wdr_p,
    input [16:0] uns_d, input [16:0] uns_a, output [34:0] uns_p,
    input signed [15:0] minc_d, input signed [15:0] minc_a, input signed [31:0] minc_c, output signed [34:0] minc_p,
    input signed [27:0] widec_d, input signed [15:0] widec_a, input signed [31:0] widec_c, output signed [45:0] widec_p
);
  assign na_p = (na_d + na_a) * na_a;
  assign wd_p = (wd_d + wd_a) * wd_a;
  assign wide_p = (wide_d + wide_a) * wide_a;
  assign min_p = (min_a - min_d) * min_a;
  assign uns_p = (uns_d + uns_a) * uns_a;
  assign minc_p = (minc_a - minc_d) * minc_a + minc_c;
  assign widec_p = (widec_d + widec_a) * widec_a + widec_c;

  reg signed [15:0] wdr_a_r;
  always @(posedge clk) begin
    wdr_a_r <= wdr_a;
  end
  assign wdr_p = (wdr_d + wdr_a_r) * wdr_a_r;
endmodule
