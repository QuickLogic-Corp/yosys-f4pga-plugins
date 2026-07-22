// CONCAT_CASCADE with no fusible consumer -> hard error (D6/D7).
module lonely (input [31:0] a, input [17:0] b, output [49:0] zc);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b010), .output_select(3'b010), .z(),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0), .z_cout(zc));
endmodule
