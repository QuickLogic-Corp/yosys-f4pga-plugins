// Cross-path: the pre-adder's sum multiplies one of its own operands.
//
// A PREADD word with the shared operand on port A would put it on ports A and
// B. The XPATH words read it once. Where no XPATH word fits, a PREADD word
// still folds it with the shared operand on port D instead.
//
//   na      (d + a) * a, a 17-bit sum fits the 18-bit B side: XPATH_A
//   wd      a 26-bit d makes a 27-bit sum, which takes the 32-bit A side: XPATH_B
//   wide    a 28-bit d does not fit port D, so a goes there: PREADD_A_MULT_B
//   min     (a - d) * a. XPATH has no subtract word; a is the minuend, so it can
//           take port D: PREADD_A_SUB_B
//   wdr     wd with a registered. The B bank absorbs the register, and the empty
//           A port must not cost it: nothing stays in fabric. XPATH_B
//   uns     unsigned 17-bit operands. Their 18-bit sum needs 19 signed bits, too
//           many for the B side; a fits B: XPATH_B
//   minc    (a - d) * a + c. No XPATH word has an ALU term, but a is the minuend
//           and takes port D: PREADD_A_SUB_B_C
//   widec   (d + a) * a + c with a 28-bit d: a takes port D: PREADD_A_MULT_B_C
//   aluc    (d + a) * a + c. No XPATH word has an ALU term. The order flips so a
//           takes port D, and d port A: PREADD_A_MULT_B_C
//   accp    p <= p + (d + a) * a, the + p form of the same: PREADD_A_MACC
//   alucr   aluc with a behind two registers. On D, a keeps one stage; the other
//           stays in fabric, and the summary says why: PREADD_A_MULT_B_C
//   naf     (a + d) * a: a written first. Same cell as na: XPATH_A
//   b18     17+17, the widest sum the 18-bit B side holds: XPATH_A
//   b19     18+18: the sum is 19, over the B side, but a (18) fits it: XPATH_B
//   d27     d at the 27-bit D limit, a 16: XPATH_B
//   s18     d 16, a at the 18-bit B limit: XPATH_B
//   mir     a * (d + a), the sum written second. Same cell as na: XPATH_A
//   aaa     (a + a) * a: both pre-adder inputs and the multiply operand are a.
//           XPATH_A, with a on D too -- not a double feed, D has its own wire
//   ext     (d + a) * aa, aa is a widened to 17 bits. Yosys strips the widening
//           before the pass sees it: XPATH_A, same as na
//   uns16   unsigned 16-bit operands. Their 17-bit sum needs 18 signed bits,
//           which just fits the B side: XPATH_A
//   uns26   unsigned, d at the 26-bit unsigned D limit, a 17: XPATH_B
//   uns27   unsigned, d one over the unsigned D limit, a 17: falls through,
//           a takes D: PREADD_A_MULT_B
//   mix     d signed, a unsigned. Verilog makes the whole expression unsigned
//   unsc    unsigned, d 17, a 17, + c. No XPATH word has an ALU term: falls
//           through, a takes D: PREADD_A_MULT_B_C
//   alucf   (a + d) * a + c, a written first: no flip needed: PREADD_A_MULT_B_C
//   accpc   p <= p + (d + a) * a + c, the + p + c form: PREADD_A_MACC_C, PREG
//   aluc18  (d + a) * a + c, d 18 and a 18 (B limit): PREADD_A_MULT_B_C
//   s32     d 31 (over D), a 16, sum 32 (the A-side limit): a takes D,
//           the sum takes the A side: PREADD_A_MULT_B
//   minacc  p <= p + (a - d) * a, the minuend takes D: PREADD_A_SUB_MACC, PREG
//   uns30   unsigned, d 30 (over D), a 16, sum 32 (the A-side limit, one bit
//           of slack under X35): PREADD_A_MULT_B
//   a2r     a behind two registers, the shared operand: XPATH_A, AREG0, AREG1
//   d1r     d behind one register, the other operand: XPATH_A, DREG
//   d2r     d behind two registers; D holds one stage, the other stays in
//           fabric: XPATH_A, DREG, "reached the bank depth limit"
//   d1a1    d and a each behind one register: XPATH_A, AREG1, DREG
//   adr     the pre-adder's own sum registered: XPATH_A, ADREG
//   preg    the multiply result registered, no feedback: XPATH_A, PREG
//   alucr1  aluc with a behind one register: PREADD_A_MULT_B_C, BREG1, DREG
//   alucd2  aluc with d behind two registers, the other operand: the register-
//           depth rule already swaps the order: PREADD_A_MULT_B_C, AREG0, AREG1
//   alucr2d2 aluc with a AND d each behind two registers; one a stage stays
//           in fabric: PREADD_A_MULT_B_C, "reached the bank depth limit"
//   accpr   accp with a behind two registers; one stage stays in fabric:
//           PREADD_A_MACC, "reached the bank depth limit"
//   ovl     (d + a[15:0]) * a, a[15:0] overlaps the whole a. The flip puts the
//           overlapping slice on D instead of leaving it on X: PREADD_A_MULT_B,
//           D = a[15:0]
//   ovlc    ovl with an ALU term: (d + a[15:0]) * a + c: PREADD_A_MULT_B_C,
//           D = a[15:0]
//   ovlr    (d + a) * a[15:0], the overlap on the multiply side instead of the
//           adder side: PREADD_A_MULT_B, D = a (the whole signal, not the slice)
//   sub     (d - a) * a. No XPATH subtract word, and a is the subtrahend, so it
//           cannot move to port D: PREADD_A_SUB_B, with a on A and B -- a word
//           that double-feeds, which programs since OpenFPGA-QL 10cd2f838
//
// X67 ("mreg": m <= (d + a) * a; p = m + c) is not included here yet. A
// pre-adder-fed multiply with an M register does not fuse its ALU term:
// measured as PREADD_A_MULT_B with c left in fabric, not PREADD_A_MULT_B_C
// with MREG. A plain multiply with the same M-register-then-add shape does
// fuse (dspv4_mult_mreg). Base P4 behavior, not cross-path's to fix here.
module dspv4_xpath (
    input clk,
    input signed [15:0] na_d, input signed [15:0] na_a, output signed [33:0] na_p,
    input signed [25:0] wd_d, input signed [15:0] wd_a, output signed [42:0] wd_p,
    input signed [27:0] wide_d, input signed [15:0] wide_a, output signed [44:0] wide_p,
    input signed [15:0] min_d, input signed [15:0] min_a, output signed [33:0] min_p,
    input signed [25:0] wdr_d, input signed [15:0] wdr_a, output signed [42:0] wdr_p,
    input [16:0] uns_d, input [16:0] uns_a, output [34:0] uns_p,
    input signed [15:0] minc_d, input signed [15:0] minc_a, input signed [31:0] minc_c, output signed [34:0] minc_p,
    input signed [27:0] widec_d, input signed [15:0] widec_a, input signed [31:0] widec_c, output signed [45:0] widec_p,
    input signed [15:0] aluc_d, input signed [15:0] aluc_a, input signed [31:0] aluc_c, output signed [34:0] aluc_p,
    input signed [15:0] accp_d, input signed [15:0] accp_a, output reg signed [49:0] accp_p,
    input signed [15:0] alucr_d, input signed [15:0] alucr_a, input signed [31:0] alucr_c, output signed [34:0] alucr_p,
    input signed [15:0] naf_d, input signed [15:0] naf_a, output signed [33:0] naf_p,
    input signed [16:0] b18_d, input signed [16:0] b18_a, output signed [35:0] b18_p,
    input signed [17:0] b19_d, input signed [17:0] b19_a, output signed [37:0] b19_p,
    input signed [26:0] d27_d, input signed [15:0] d27_a, output signed [44:0] d27_p,
    input signed [15:0] s18_d, input signed [17:0] s18_a, output signed [35:0] s18_p,
    input signed [15:0] mir_d, input signed [15:0] mir_a, output signed [33:0] mir_p,
    input signed [15:0] aaa_a, output signed [33:0] aaa_p,
    input signed [15:0] ext_d, input signed [15:0] ext_a, output signed [33:0] ext_p,
    input [15:0] uns16_d, input [15:0] uns16_a, output [32:0] uns16_p,
    input [25:0] uns26_d, input [16:0] uns26_a, output [43:0] uns26_p,
    input [26:0] uns27_d, input [16:0] uns27_a, output [44:0] uns27_p,
    input signed [15:0] mix_d, input [15:0] mix_a, output [32:0] mix_p,
    input [16:0] unsc_d, input [16:0] unsc_a, input signed [31:0] unsc_c, output [35:0] unsc_p,
    input signed [15:0] alucf_d, input signed [15:0] alucf_a, input signed [31:0] alucf_c, output signed [34:0] alucf_p,
    input signed [15:0] accpc_d, input signed [15:0] accpc_a, input signed [31:0] accpc_c, output reg signed [49:0] accpc_p,
    input signed [17:0] aluc18_d, input signed [17:0] aluc18_a, input signed [31:0] aluc18_c, output signed [37:0] aluc18_p,
    input signed [30:0] s32_d, input signed [15:0] s32_a, output signed [48:0] s32_p,
    input signed [15:0] minacc_d, input signed [15:0] minacc_a, output reg signed [49:0] minacc_p,
    input [29:0] uns30_d, input [15:0] uns30_a, output [47:0] uns30_p,
    input signed [15:0] a2r_d, input signed [15:0] a2r_a, output signed [33:0] a2r_p,
    input signed [15:0] d1r_d, input signed [15:0] d1r_a, output signed [33:0] d1r_p,
    input signed [15:0] d2r_d, input signed [15:0] d2r_a, output signed [33:0] d2r_p,
    input signed [15:0] d1a1_d, input signed [15:0] d1a1_a, output signed [33:0] d1a1_p,
    input signed [15:0] adr_d, input signed [15:0] adr_a, output signed [33:0] adr_p,
    input signed [15:0] preg_d, input signed [15:0] preg_a, output reg signed [33:0] preg_p,
    input signed [15:0] alucr1_d, input signed [15:0] alucr1_a, input signed [31:0] alucr1_c, output signed [34:0] alucr1_p,
    input signed [15:0] alucd2_d, input signed [15:0] alucd2_a, input signed [31:0] alucd2_c, output signed [34:0] alucd2_p,
    input signed [15:0] alucr2d2_d, input signed [15:0] alucr2d2_a, input signed [31:0] alucr2d2_c, output signed [34:0] alucr2d2_p,
    input signed [15:0] accpr_d, input signed [15:0] accpr_a, output reg signed [49:0] accpr_p,
    input signed [15:0] ovl_d, input signed [16:0] ovl_a, output signed [33:0] ovl_p,
    input signed [15:0] ovlc_d, input signed [16:0] ovlc_a, input signed [31:0] ovlc_c, output signed [34:0] ovlc_p,
    input signed [15:0] ovlr_d, input signed [16:0] ovlr_a, output signed [33:0] ovlr_p,
    input signed [15:0] sub_d, input signed [15:0] sub_a, output signed [33:0] sub_p
);
  assign na_p = (na_d + na_a) * na_a;
  assign wd_p = (wd_d + wd_a) * wd_a;
  assign wide_p = (wide_d + wide_a) * wide_a;
  assign min_p = (min_a - min_d) * min_a;
  assign uns_p = (uns_d + uns_a) * uns_a;
  assign minc_p = (minc_a - minc_d) * minc_a + minc_c;
  assign widec_p = (widec_d + widec_a) * widec_a + widec_c;

  reg signed [15:0] wdr_a_r;
  always @(posedge clk) begin
    wdr_a_r <= wdr_a;
  end
  assign wdr_p = (wdr_d + wdr_a_r) * wdr_a_r;

  assign aluc_p = (aluc_d + aluc_a) * aluc_a + aluc_c;
  always @(posedge clk) begin
    accp_p <= accp_p + (accp_d + accp_a) * accp_a;
  end

  reg signed [15:0] alucr_a1, alucr_a2;
  always @(posedge clk) begin
    alucr_a1 <= alucr_a;
    alucr_a2 <= alucr_a1;
  end
  assign alucr_p = (alucr_d + alucr_a2) * alucr_a2 + alucr_c;

  assign naf_p = (naf_a + naf_d) * naf_a;
  assign b18_p = (b18_d + b18_a) * b18_a;
  assign b19_p = (b19_d + b19_a) * b19_a;
  assign d27_p = (d27_d + d27_a) * d27_a;
  assign s18_p = (s18_d + s18_a) * s18_a;
  assign mir_p = mir_a * (mir_d + mir_a);
  assign aaa_p = (aaa_a + aaa_a) * aaa_a;

  wire signed [16:0] ext_aa = ext_a;
  assign ext_p = (ext_d + ext_a) * ext_aa;

  assign uns16_p = (uns16_d + uns16_a) * uns16_a;
  assign uns26_p = (uns26_d + uns26_a) * uns26_a;
  assign uns27_p = (uns27_d + uns27_a) * uns27_a;
  assign mix_p = (mix_d + mix_a) * mix_a;
  assign unsc_p = (unsc_d + unsc_a) * unsc_a + unsc_c;
  assign alucf_p = (alucf_a + alucf_d) * alucf_a + alucf_c;
  always @(posedge clk) begin
    accpc_p <= accpc_p + (accpc_d + accpc_a) * accpc_a + accpc_c;
  end
  assign aluc18_p = (aluc18_d + aluc18_a) * aluc18_a + aluc18_c;
  assign s32_p = (s32_d + s32_a) * s32_a;
  always @(posedge clk) begin
    minacc_p <= minacc_p + (minacc_a - minacc_d) * minacc_a;
  end
  assign uns30_p = (uns30_d + uns30_a) * uns30_a;

  reg signed [15:0] a2r_a1, a2r_a2;
  always @(posedge clk) begin
    a2r_a1 <= a2r_a;
    a2r_a2 <= a2r_a1;
  end
  assign a2r_p = (a2r_d + a2r_a2) * a2r_a2;

  reg signed [15:0] d1r_d1;
  always @(posedge clk) begin
    d1r_d1 <= d1r_d;
  end
  assign d1r_p = (d1r_d1 + d1r_a) * d1r_a;

  reg signed [15:0] d2r_d1, d2r_d2;
  always @(posedge clk) begin
    d2r_d1 <= d2r_d;
    d2r_d2 <= d2r_d1;
  end
  assign d2r_p = (d2r_d2 + d2r_a) * d2r_a;

  reg signed [15:0] d1a1_d1, d1a1_a1;
  always @(posedge clk) begin
    d1a1_d1 <= d1a1_d;
    d1a1_a1 <= d1a1_a;
  end
  assign d1a1_p = (d1a1_d1 + d1a1_a1) * d1a1_a1;

  reg signed [16:0] adr_s_r;
  always @(posedge clk) begin
    adr_s_r <= adr_d + adr_a;
  end
  assign adr_p = adr_s_r * adr_a;

  always @(posedge clk) begin
    preg_p <= (preg_d + preg_a) * preg_a;
  end

  reg signed [15:0] alucr1_a1;
  always @(posedge clk) begin
    alucr1_a1 <= alucr1_a;
  end
  assign alucr1_p = (alucr1_d + alucr1_a1) * alucr1_a1 + alucr1_c;

  reg signed [15:0] alucd2_d1, alucd2_d2;
  always @(posedge clk) begin
    alucd2_d1 <= alucd2_d;
    alucd2_d2 <= alucd2_d1;
  end
  assign alucd2_p = (alucd2_d2 + alucd2_a) * alucd2_a + alucd2_c;

  reg signed [15:0] alucr2d2_d1, alucr2d2_d2, alucr2d2_a1, alucr2d2_a2;
  always @(posedge clk) begin
    alucr2d2_d1 <= alucr2d2_d;
    alucr2d2_d2 <= alucr2d2_d1;
    alucr2d2_a1 <= alucr2d2_a;
    alucr2d2_a2 <= alucr2d2_a1;
  end
  assign alucr2d2_p = (alucr2d2_d2 + alucr2d2_a2) * alucr2d2_a2 + alucr2d2_c;

  reg signed [15:0] accpr_a1, accpr_a2;
  always @(posedge clk) begin
    accpr_a1 <= accpr_a;
    accpr_a2 <= accpr_a1;
    accpr_p <= accpr_p + (accpr_d + accpr_a2) * accpr_a2;
  end

  assign ovl_p = (ovl_d + $signed(ovl_a[15:0])) * ovl_a;
  assign ovlc_p = (ovlc_d + $signed(ovlc_a[15:0])) * ovlc_a + ovlc_c;
  assign ovlr_p = (ovlr_d + ovlr_a) * $signed(ovlr_a[15:0]);
  assign sub_p = (sub_d - sub_a) * sub_a;
endmodule
