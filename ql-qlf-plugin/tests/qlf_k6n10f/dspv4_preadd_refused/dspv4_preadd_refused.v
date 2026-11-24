// Pre-adder shapes the pass must REFUSE.
//
// Each leaves the addition in fabric and puts only the multiply in the DSP --
// in two DSPs when the fabric sum is too wide for one port. Kept apart from the
// folding shapes on purpose: merged, a cell count could not tell a refusal that
// happened from a fold that happened in its place.
//
//   pad    the sum is zero-padded, so the RTL value is non-negative where the
//          DSP's pre-adder would keep the sign
//   trunc  the sum is narrower than the addition it holds, so the RTL wraps
//          where the DSP would carry on
//   unsgn  unsigned operands read through $signed, so the two disagree
//   over   18+18, one bit wider than the D port holds
//
// Unsigned operands whose top bits are ones. Their top bits are value bits,
// not copies of a sign: an all-ones constant is large, not -1.
//
//   ones32     (d + 31'h7FFFFFFF) * b: the sum needs 33 signed bits, AD has 32
//   ones18b    (d + 17'h1FFFF) * b, b 20: the sum needs 19 signed bits, the
//              B side has 18, and b is too wide to leave it the A side
//   onestrunc  s = d + 16'hFFFF with s 16 bits: the sum needs 17, so the RTL
//              wraps
//   copies     d + {{9{a[7]}}, a}: copied top bits are value bits too; the sum
//              needs 19 signed bits, the B side has 18
//   unsdiff    18'h3FFFF - a: the difference needs 19 signed bits, the B side
//              has 18
module dspv4_preadd_refused (
    input signed [15:0] pad_a, input signed [15:0] pad_b,
    input signed [15:0] pad_c, output signed [34:0] pad_y,
    input signed [15:0] trunc_a, input signed [15:0] trunc_b,
    input signed [15:0] trunc_c, output signed [31:0] trunc_y,
    input [15:0] unsgn_a, input [15:0] unsgn_b,
    input signed [15:0] unsgn_c, output signed [33:0] unsgn_y,
    input signed [17:0] over_d, input signed [17:0] over_a,
    input signed [31:0] over_b, output signed [49:0] over_p,
    input [25:0] ones32_d, input [7:0] ones32_b, output [39:0] ones32_p,
    input [7:0] ones18b_d, input [19:0] ones18b_b, output [37:0] ones18b_p,
    input [7:0] onestrunc_d, input [19:0] onestrunc_b, output [35:0] onestrunc_p,
    input [7:0] copies_d, input [7:0] copies_a, input [19:0] copies_b, output [37:0] copies_p,
    input [7:0] unsdiff_a, input [19:0] unsdiff_b, output [18:0] unsdiff_p
);
  wire signed [16:0] pad_s = pad_a + pad_b;
  assign pad_y = $signed({1'b0, pad_s}) * pad_c;

  wire signed [15:0] trunc_s = trunc_a + trunc_b;
  assign trunc_y = trunc_s * trunc_c;

  wire [16:0] unsgn_s = unsgn_a + unsgn_b;
  assign unsgn_y = $signed(unsgn_s) * unsgn_c;

  assign over_p = (over_d + over_a) * over_b;

  assign ones32_p = (ones32_d + 31'h7FFFFFFF) * ones32_b;
  assign ones18b_p = (ones18b_d + 17'h1FFFF) * ones18b_b;

  wire [15:0] onestrunc_s = onestrunc_d + 16'hFFFF;
  assign onestrunc_p = onestrunc_s * onestrunc_b;

  wire [17:0] copies_s = copies_d + {{9{copies_a[7]}}, copies_a};
  assign copies_p = copies_s * copies_b;

  wire [18:0] unsdiff_s = 18'h3FFFF - unsdiff_a;
  assign unsdiff_p = unsdiff_s * unsdiff_b;
endmodule
