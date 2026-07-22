// DSP-to-DSP product cascade via z_cout -> z_cin (as in cascade_chain):
//   stage1 MULT (a1*b1) drives `casc` on its z_cout;
//   stage2 MULTADD (casc + a2*b2) reads `casc` on z_cin.
// The pass must wire stage1.z_cout -> PCOUT and stage2.z_cin -> PCIN onto the same
// net so the cascade is preserved (P1-FR-4) -- no undriven PCIN.
module cascade (input [31:0] a1, a2, input [17:0] b1, b2, output [49:0] p);
  wire [49:0] casc;
  QL_DSPV2 #(.MODE_BITS(80'h0)) s1 (.a(a1), .b(b1), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b000), .z(), .z_cout(casc),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
  QL_DSPV2 #(.MODE_BITS(80'h00800000000000000000)) s2 (.a(a2), .b(b2), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b011), .output_select(3'b010), .z(p),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(casc));
endmodule
