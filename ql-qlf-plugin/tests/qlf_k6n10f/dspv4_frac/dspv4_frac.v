// FRAC_MODE (bit79) set -> V2-only config, no V4 analogue (MM-6).
module frac (input [31:0] a, input [17:0] b, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h80000000000000000000)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b000), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule
