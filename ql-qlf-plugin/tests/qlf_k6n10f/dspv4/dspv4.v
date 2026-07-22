// Test designs for the ql_dspv4 pass: generic QL_DSPV2 cells (as Synplify emits).
// MODE_BITS/feedback/output_select select the recognized V2 mode.

// MULT: control word 0x00
module mult (input [31:0] a, input [17:0] b, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b000), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// MULTACC: output_select=1 -> control word 0x08 (accumulate -> PREG=1).
// load_acc is a CONSTANT (1) -> accumulate every cycle; V4 has no dynamic
// load_acc, so a constant is required (a variable load_acc hard-errors, see the
// dspv4_dynload negative test).
module multacc (input [31:0] a, input [17:0] b, input clk, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b1),
    .feedback(3'b000), .output_select(3'b001), .z(z),
    .clk(clk), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// MULTACC with constant load_acc=0 (hold): CEP ties to 0 (static). Converts to a
// QL_DSP4; a *variable* load_acc would instead hard-error (see dspv4_dynload).
module multacc_hold (input [31:0] a, input [17:0] b, input clk, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b001), .z(z),
    .clk(clk), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// MULTACC + output register (output_select=5 -> MULTACC & out_reg): PREG holds
// the accumulator, so the extra V2 output register becomes an external dffre on P.
module multacc_oreg (input [31:0] a, input [17:0] b, input clk, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b1),
    .feedback(3'b000), .output_select(3'b101), .z(z),
    .clk(clk), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// Fusion: CONCAT_CASCADE (fb=2,os=2) z_cout -> MULTADD (fb=3,os=2,bit71=1) z_cin
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

// FRAC_MODE (bit79) -> V2-only config hard error (MM-6)
module frac (input [31:0] a, input [17:0] b, output [49:0] z);
  QL_DSPV2 #(.MODE_BITS(80'h80000000000000000000)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b000), .output_select(3'b000), .z(z),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0));
endmodule

// Lonely CONCAT_CASCADE (no fusible consumer) -> hard error (D6/D7)
module lonely (input [31:0] a, input [17:0] b, output [49:0] zc);
  QL_DSPV2 #(.MODE_BITS(80'h0)) u (.a(a), .b(b), .c(18'h0), .load_acc(1'b0),
    .feedback(3'b010), .output_select(3'b010), .z(),
    .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
    .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0), .z_cout(zc));
endmodule

// k>=2 fusion: fully-pipelined CONCAT_CASCADE_REGIN_REGOUT -- one input register
// (A2_REG, bit63) + one output register (output_select[2]) => addend delay k=2,
// which the single V4 C-path register (CREG) cannot reproduce -> hard error (MM-7).
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
