// Negative test: an accumulate mode (MULTACC) with a NON-CONSTANT (variable)
// load_acc. DSP-V4 has no dynamic accumulate-load control, so this is not
// supported and ql_dspv2_to_dspv4 must hard-error (CASE 2/3, P1-FR-6).
module dynload (input [31:0] a, input [17:0] b, input le, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(le),
    .feedback(3'b000), .output_select(3'b001), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule
