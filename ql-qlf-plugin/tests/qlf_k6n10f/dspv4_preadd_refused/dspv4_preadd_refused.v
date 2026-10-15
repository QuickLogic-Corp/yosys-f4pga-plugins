// Pre-adder shapes the pass must REFUSE, each for a different reason.
//
// All four leave the addition in fabric and put only the multiply in the DSP.
// Kept apart from the folding shapes on purpose: merged, a cell count could
// not tell a refusal that happened from a fold that happened in its place.
//
//   pad    the sum is zero-padded, so the RTL value is non-negative where the
//          DSP's pre-adder would keep the sign
//   trunc  the sum is narrower than the addition it holds, so the RTL wraps
//          where the DSP would carry on
//   unsgn  unsigned operands read through $signed, so the two disagree
//   over   18+18, one bit wider than the D port holds
module dspv4_preadd_refused (
    input signed [15:0] pad_a, input signed [15:0] pad_b,
    input signed [15:0] pad_c, output signed [34:0] pad_y,
    input signed [15:0] trunc_a, input signed [15:0] trunc_b,
    input signed [15:0] trunc_c, output signed [31:0] trunc_y,
    input [15:0] unsgn_a, input [15:0] unsgn_b,
    input signed [15:0] unsgn_c, output signed [33:0] unsgn_y,
    input signed [17:0] over_d, input signed [17:0] over_a,
    input signed [31:0] over_b, output signed [49:0] over_p
);
  wire signed [16:0] pad_s = pad_a + pad_b;
  assign pad_y = $signed({1'b0, pad_s}) * pad_c;

  wire signed [15:0] trunc_s = trunc_a + trunc_b;
  assign trunc_y = trunc_s * trunc_c;

  wire [16:0] unsgn_s = unsgn_a + unsgn_b;
  assign unsgn_y = $signed(unsgn_s) * unsgn_c;

  assign over_p = (over_d + over_a) * over_b;
endmodule
