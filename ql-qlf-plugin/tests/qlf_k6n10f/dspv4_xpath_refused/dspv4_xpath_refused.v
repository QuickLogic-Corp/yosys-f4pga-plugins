// Cross-path shapes that must not fold. Each keeps its multiply in a DSP and
// its pre-adder's work in fabric.
//
//   sub     (d - a) * a. No XPATH subtract word, and a is the subtrahend, so it
//           cannot move to port D. The only PREADD word puts a on A and B, which
//           the double-feed check refuses: MULT
//   subc    (d - a) * a + c. No XPATH word has an ALU term, and a is the
//           subtrahend, so it cannot move to port D: MULT_ADD_C
//   s19     (d + a) * a, a 19 (over the B side): the multiply itself does not
//           fit, so it is split, with no pre-adder in use: two MULT cells
//   ovl     (d + $signed(a[15:0])) * a, a[15:0] overlaps the full a. The written
//           order puts the slice on X, so the pre-adder wants a on A and B:
//           MULT, the double-feed line
//   rd3     s = d + a; p = s * a; s_out = s. The sum has a third reader, so the
//           matcher's own fanout bound refuses the pre-adder, silently: MULT
//   trunc   wire [15:0] s = d + a; s * a. The sum is truncated to 16 bits: MULT,
//           "it truncates its own sum"
//   aaac    (a + a) * a + c. No XPATH word has an ALU term: MULT_ADD_C
//   uns18   unsigned, d 18 and a 18 (over the unsigned B side): the multiply
//           does not fit, split: two MULT cells
//   usub    (a - d) * a, unsigned. An unsigned subtract wraps where the DSP
//           signs, and the multiply is also too wide: two MULT cells
//   usubs   (d - a) * a, unsigned, the subtrahend shared. As usub, but the
//           unsigned-subtract reason comes before the double-feed check
//   accs    p <= p + (d - a) * a. The ALU-term line, as subc, with the
//           subtract in fabric: MULT_ACC
//   csub    c - (d + a) * a. No PREADD word subtracts the product from C:
//           MULT_SUB_C
//   rsub    (d + a) * a - c. No PREADD word subtracts C from the product:
//           MULT_RSUB_C
//   alu19   (d + a) * a + c, a 19 (over the B side): the multiply is split,
//           c added in fabric
//   s33     (d + a) * a, d 32 (over D), sum 33 (over the A side too): split
//   accsub  p <= p - (d + a) * a. No PREADD word subtracts the product from P:
//           MULT_ACC_SUB, PREG
//   uns31   (d + a) * a, unsigned, d 31 (over AD once the unsigned bit is
//           counted): the A-path site of the unsigned-sum-width bug. Split
//   uns17b  (d + a) * b, unsigned, d and a 17, b 20 (over port B): the B-path
//           site of the same bug, which b's width forces onto that side. Split
module dspv4_xpath_refused (
    input clk,
    input signed [15:0] sub_d, input signed [15:0] sub_a, output signed [33:0] sub_p,
    input signed [15:0] subc_d, input signed [15:0] subc_a,
    input signed [31:0] subc_c, output signed [34:0] subc_p,
    input signed [15:0] s19_d, input signed [18:0] s19_a, output signed [37:0] s19_p,
    input signed [15:0] ovl_d, input signed [16:0] ovl_a, output signed [33:0] ovl_p,
    input signed [15:0] rd3_d, input signed [15:0] rd3_a, output signed [33:0] rd3_p,
    output signed [16:0] rd3_s_out,
    input signed [15:0] trunc_d, input signed [15:0] trunc_a, output signed [31:0] trunc_p,
    input signed [15:0] aaac_a, input signed [31:0] aaac_c, output signed [34:0] aaac_p,
    input [17:0] uns18_d, input [17:0] uns18_a, output [35:0] uns18_p,
    input [15:0] usub_d, input [15:0] usub_a, output [31:0] usub_p,
    input [15:0] usubs_d, input [15:0] usubs_a, output [31:0] usubs_p,
    input signed [15:0] accs_d, input signed [15:0] accs_a, output reg signed [49:0] accs_p,
    input signed [15:0] csub_d, input signed [15:0] csub_a,
    input signed [31:0] csub_c, output signed [34:0] csub_p,
    input signed [15:0] rsub_d, input signed [15:0] rsub_a,
    input signed [31:0] rsub_c, output signed [34:0] rsub_p,
    input signed [15:0] alu19_d, input signed [18:0] alu19_a,
    input signed [31:0] alu19_c, output signed [37:0] alu19_p,
    input signed [31:0] s33_d, input signed [15:0] s33_a, output signed [49:0] s33_p,
    input signed [15:0] accsub_d, input signed [15:0] accsub_a, output reg signed [49:0] accsub_p,
    input [30:0] uns31_d, input [15:0] uns31_a, output [46:0] uns31_p,
    input [16:0] uns17b_d, input [16:0] uns17b_a, input [19:0] uns17b_b, output [37:0] uns17b_p
);
  assign sub_p = (sub_d - sub_a) * sub_a;
  assign subc_p = (subc_d - subc_a) * subc_a + subc_c;
  assign s19_p = (s19_d + s19_a) * s19_a;
  assign ovl_p = (ovl_d + $signed(ovl_a[15:0])) * ovl_a;

  wire signed [16:0] rd3_s = rd3_d + rd3_a;
  assign rd3_p = rd3_s * rd3_a;
  assign rd3_s_out = rd3_s;

  wire [15:0] trunc_s = trunc_d + trunc_a;
  assign trunc_p = trunc_s * trunc_a;

  assign aaac_p = (aaac_a + aaac_a) * aaac_a + aaac_c;
  assign uns18_p = (uns18_d + uns18_a) * uns18_a;
  assign usub_p = (usub_a - usub_d) * usub_a;
  assign usubs_p = (usubs_d - usubs_a) * usubs_a;

  always @(posedge clk) begin
    accs_p <= accs_p + (accs_d - accs_a) * accs_a;
  end

  assign csub_p = csub_c - (csub_d + csub_a) * csub_a;
  assign rsub_p = (rsub_d + rsub_a) * rsub_a - rsub_c;
  assign alu19_p = (alu19_d + alu19_a) * alu19_a + alu19_c;
  assign s33_p = (s33_d + s33_a) * s33_a;

  always @(posedge clk) begin
    accsub_p <= accsub_p - (accsub_d + accsub_a) * accsub_a;
  end

  assign uns31_p = (uns31_d + uns31_a) * uns31_a;
  assign uns17b_p = (uns17b_d + uns17b_a) * uns17b_b;
endmodule
