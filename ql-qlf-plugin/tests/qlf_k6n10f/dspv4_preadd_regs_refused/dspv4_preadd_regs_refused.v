// Pre-adder registers the DSP must NOT absorb, each for a different reason.
//
// Kept apart from dspv4_preadd_regs on purpose: merged, a cell count could not
// tell a refusal that happened from a fold that happened in its place.
//
// The AD register after the pre-adder (ffb preadd_path.v:117-127) has no
// enable, resets synchronously to zero on the cell's shared RSTN, and nothing
// else:
//
//   en   AD register with an enable: the bank has none
//   re   AD register with an enable and a reset: still the enable
//   nz   AD register resets to 5: the bank resets to zero
//   as   AD register with an async reset: the bank's reset is synchronous
//   mr   AD and M registers on different resets: both banks take RSTN, so
//        they cannot share a cell, and the M register cannot be given up
//   ck   AD register on clk2, B register on clk: one cell has one clock
//   ki   AD register powers up at 1: the bank powers up at 0. Each AD offer
//        gives up the resetless B chain, then is refused, so the summary
//        must not report that chain as given up
//
// The registers before the pre-adder. D holds one stage and A two, so an add
// swaps its operands to put a two-deep chain on A. These three cannot:
//
//   sub  a subtract: the DSP computes D - A and has no A - D (preadder.v:21)
//   wd   the other operand is 28 bits and D holds 27
//   me   the two stages have different enables, and A1 and A2 share CEA
module dspv4_preadd_regs_refused (
    input clk, clk2, rstn, rst2n, arstn,
    input en_en, input signed [15:0] en_d, en_a, en_b, output signed [32:0] en_p,
    input re_en, input signed [15:0] re_d, re_a, re_b, output signed [32:0] re_p,
    input signed [15:0] nz_d, nz_a, nz_b, output signed [32:0] nz_p,
    input signed [15:0] as_d, as_a, as_b, output signed [32:0] as_p,
    input signed [15:0] mr_d, mr_a, mr_b, input signed [32:0] mr_c, output signed [33:0] mr_p,
    input signed [15:0] sub_d, sub_a, sub_b, output signed [32:0] sub_p,
    input signed [15:0] wd_d, input signed [27:0] wd_a, input signed [15:0] wd_b, output signed [44:0] wd_p,
    input signed [15:0] ck_d, ck_a, ck_b, output signed [32:0] ck_p,
    input me_en0, me_en1, input signed [15:0] me_d, me_a, me_b, output signed [32:0] me_p,
    input signed [15:0] ki_d, ki_a, ki_b, output signed [32:0] ki_p
);
  reg signed [16:0] en_ad, re_ad, nz_ad, as_ad, mr_ad, ck_ad;
  reg signed [16:0] ki_ad = 17'sd1;
  reg signed [32:0] mr_m;
  reg signed [15:0] sub_q0, sub_q1, wd_q0, wd_q1, ck_bq, me_q0, me_q1, ki_bq;

  assign en_p  = en_ad * en_b;
  assign re_p  = re_ad * re_b;
  assign nz_p  = nz_ad * nz_b;
  assign as_p  = as_ad * as_b;
  assign mr_p  = mr_m + mr_c;
  assign sub_p = (sub_q1 - sub_a) * sub_b;
  assign wd_p  = (wd_q1 + wd_a) * wd_b;
  assign ck_p  = ck_ad * ck_bq;
  assign me_p  = (me_q1 + me_a) * me_b;
  assign ki_p  = ki_ad * ki_bq;

  always @(posedge clk) begin
    if (en_en) en_ad <= en_d + en_a;
    if (!rstn)      re_ad <= 0;
    else if (re_en) re_ad <= re_d + re_a;
    if (!rstn) nz_ad <= 17'sd5;
    else       nz_ad <= nz_d + nz_a;
    if (!rstn) mr_ad <= 0;
    else       mr_ad <= mr_d + mr_a;
    if (!rst2n) mr_m <= 0;
    else        mr_m <= mr_ad * mr_b;
    sub_q0 <= sub_d;
    sub_q1 <= sub_q0;
    wd_q0  <= wd_d;
    wd_q1  <= wd_q0;
    if (!rstn) ck_bq <= 0;
    else       ck_bq <= ck_b;
    if (me_en0) me_q0 <= me_d;
    if (me_en1) me_q1 <= me_q0;
    if (!rstn) ki_ad <= 0;
    else       ki_ad <= ki_d + ki_a;
    ki_bq <= ki_b;
  end

  always @(posedge clk2)
    if (!rstn) ck_ad <= 0;
    else       ck_ad <= ck_d + ck_a;

  always @(posedge clk or negedge arstn)
    if (!arstn) as_ad <= 0;
    else        as_ad <= as_d + as_a;
endmodule
