// Fusion with addend latency k=2: fully-pipelined CONCAT_CASCADE_REGIN_REGOUT --
// one input register (A2_REG, bit63) + one output register (output_select[2]) =>
// k=2, unreproducible by the single V4 C-path register -> hard error (MM-7).
module k2 (input [31:0] a0, input [17:0] b0, input [31:0] a1, input [17:0] b1, output [49:0] z);
  wire [49:0] casc;
  QL_DSPV2 #(.MODE_BITS(80'h00008000000000000000)) concat (.a(a1), .b(b1), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b010), .output_select(3'b110), .z(),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0), .z_cout(casc));
  QL_DSPV2 #(.MODE_BITS(80'h00800000000000000000)) madd (.a(a0), .b(b0), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b011), .output_select(3'b010), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(casc));
endmodule
