// `(d + a) * b` at every width the pre-adder accepts.
//
// One design because all six fold. The widths that must be REFUSED live in
// dspv4_preadd_refused -- summed together, a total could not tell a fold that
// happened from a refusal that happened in its place.
//
//   narrow  16+16 into an 18-bit multiply operand -> A path
//   wide    16+16 against a 32-bit b              -> B path
//   edge    17+17, the widest sum the D port holds
//   konst   a constant addend, folded the same way
//   onesa   unsigned (d + 30'h3FFFFFFF) * b: the sum needs exactly AD's 32
//           signed bits -> A path. One more and it is refused (ones32)
//   onesb   unsigned (d + 16'hFFFF) * b, b 20: the sum needs exactly the B
//           side's 18 signed bits -> B path. One more and it is refused (ones18b)
module dspv4_preadd_widths (
    input signed [15:0] narrow_d, input signed [15:0] narrow_a,
    input signed [17:0] narrow_b, output signed [34:0] narrow_p,
    input signed [15:0] wide_d, input signed [15:0] wide_a,
    input signed [31:0] wide_b, output signed [49:0] wide_p,
    input signed [16:0] edge_d, input signed [16:0] edge_a,
    input signed [31:0] edge_b, output signed [49:0] edge_p,
    input signed [16:0] konst_d,
    input signed [31:0] konst_b, output signed [49:0] konst_p,
    input [25:0] onesa_d, input [7:0] onesa_b, output [39:0] onesa_p,
    input [7:0] onesb_d, input [19:0] onesb_b, output [37:0] onesb_p
);
  assign narrow_p = (narrow_d + narrow_a) * narrow_b;
  assign wide_p   = (wide_d + wide_a) * wide_b;
  assign edge_p   = (edge_d + edge_a) * edge_b;
  assign konst_p  = (konst_d + 18'sd100) * konst_b;
  assign onesa_p  = (onesa_d + 30'h3FFFFFFF) * onesa_b;
  assign onesb_p  = (onesb_d + 16'hFFFF) * onesb_b;
endmodule
