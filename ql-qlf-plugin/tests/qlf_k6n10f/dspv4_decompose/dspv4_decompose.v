// Phase-2 decompose tests: generic QL_DSPV2 cells (as Synplify emits) are first
// converted to monolithic QL_DSP4 (ql_dspv2_to_dspv4), then decomposed by the
// dsp4_logical techmap into leaf cells (QL_DSP4_MULT / _ALU_ADD / _PREADD /
// _ACC_DFFRE / ...). The .tcl asserts the expected leaf cells appear and no
// QL_DSP4 / QL_DSPV2 remains.

// MULT: A*B  -> mult + alu_add, no registers, no RSS.
module mult (input [31:0] a, input [17:0] b, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b000), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// MULTACC: acc + A*B -> mult + alu_add + 64-bit accumulator register (PREG=1).
module multacc (input [31:0] a, input [17:0] b, input clk, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b1),
    .feedback(3'b000), .output_select(3'b001), .z(z),
    .clk(clk), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// PREADDER_MULT: (D+B)*A -> pre-adder (add) + mult + alu_add. MODE_BITS bit59
// (PRE_ADD)=1; c is the pre-adder operand (-> V4 D).
module preadd_mult (input [31:0] a, input [17:0] b, input [17:0] c, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h00000800000000000000)) u (.a(a), .b(b), .c(c), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b000), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// Fusion: CONCAT_CASCADE (fb=2,os=2) z_cout -> MULTADD (fb=3,os=2,bit71=1) z_cin.
// Fuses to one QL_DSP4 (A*B+C, C={A1,B1}) -> mult + alu_add (k=0 -> no C reg).
module fuse (input [31:0] a0, input [17:0] b0, input [31:0] a1, input [17:0] b1, output [49:0] z);
  wire [49:0] casc;
  QL_DSPV2 #(.MODE_BITS(80'h0)) concat (.a(a1), .b(b1), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b010), .output_select(3'b010), .z(),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0), .z_cout(casc));
  QL_DSPV2 #(.MODE_BITS(80'h00800000000000000000)) madd (.a(a0), .b(b0), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b011), .output_select(3'b010), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(casc));
endmodule
