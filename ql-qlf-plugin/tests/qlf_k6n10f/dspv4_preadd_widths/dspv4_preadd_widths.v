// `(d + a) * b` at every width the pre-adder accepts.
//
// One design because all four fold. The widths that must be REFUSED live in
// dspv4_preadd_refused -- summed together, a total could not tell a fold that
// happened from a refusal that happened in its place.
//
//   narrow  16+16 into an 18-bit multiply operand -> A path
//   wide    16+16 against a 32-bit b              -> B path
//   edge    17+17, the widest sum the D port holds
//   konst   a constant addend, folded the same way
module dspv4_preadd_widths (
    input signed [15:0] narrow_d, input signed [15:0] narrow_a,
    input signed [17:0] narrow_b, output signed [34:0] narrow_p,
    input signed [15:0] wide_d, input signed [15:0] wide_a,
    input signed [31:0] wide_b, output signed [49:0] wide_p,
    input signed [16:0] edge_d, input signed [16:0] edge_a,
    input signed [31:0] edge_b, output signed [49:0] edge_p,
    input signed [16:0] konst_d,
    input signed [31:0] konst_b, output signed [49:0] konst_p
);
  assign narrow_p = (narrow_d + narrow_a) * narrow_b;
  assign wide_p   = (wide_d + wide_a) * wide_b;
  assign edge_p   = (edge_d + edge_a) * edge_b;
  assign konst_p  = (konst_d + 18'sd100) * konst_b;
endmodule
