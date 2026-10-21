// Every pre-adder shape whose registers the DSP is expected to ABSORB.
//
// Six groups, folded into one design because they all assert the same
// outcome: the pre-adder survives and no carry chain is left in fabric. The
// shapes that must be REFUSED live in their own tests -- mixing the two here
// would mean asserting totals, and a total cannot tell a fold that happened
// from a refusal that happened in its place.
//
//   ad_*  the pre-adder's output register, narrow and wide operands
//   dr_*  D and AD banks at every depth from 0 to 2
//   as_*  D deeper than A: the operands swap, so the two-deep chain takes A1
//         and A2 and the one-deep one takes D
//   en_*  clock enables, including one cell wanting more than the DSP routes
//   bs_*  the swap on the B path: the two-deep chain takes B1 and B2
//   ce_*  the swap with enables: the moved chain brings its enable to CEA,
//         in a cell that still wants one enable more than the DSP routes
//
// D holds one stage and A or B hold two, so an add whose two-deep chain
// arrives on D swaps its operands. dr_p2, dr_p5, as_p, bs_p and ce_p do.
module dspv4_preadd_regs (
    input clk,
    // AD register alone, narrow and wide.
    input signed [15:0] ad_d, input signed [15:0] ad_a, input signed [15:0] ad_b,
    output signed [32:0] ad_p,
    input signed [15:0] ad_wd, input signed [15:0] ad_wa, input signed [31:0] ad_wb,
    output signed [48:0] ad_wp,
    // D 0/1/2 deep against AD 0/1 deep.
    input signed [15:0] dr_d0, dr_a0, dr_b0, output signed [32:0] dr_p0,
    input signed [15:0] dr_d1, dr_a1, dr_b1, output signed [32:0] dr_p1,
    input signed [15:0] dr_d2, dr_a2, dr_b2, output signed [32:0] dr_p2,
    input signed [15:0] dr_d3, dr_a3, dr_b3, output signed [32:0] dr_p3,
    input signed [15:0] dr_d4, dr_a4, dr_b4, output signed [32:0] dr_p4,
    input signed [15:0] dr_d5, dr_a5, dr_b5, output signed [32:0] dr_p5,
    // D two deep, A one deep.
    input signed [15:0] as_d, as_a, as_b, output signed [32:0] as_p,
    // One enable on D alone.
    input en0, input signed [15:0] en_d0, en_a0, en_b0, output signed [32:0] en_p0,
    // Four distinct enables: one more than the DSP routes, so B is evicted.
    input en_d, input en_a, input en_b, input en_p,
    input signed [15:0] en_d1, en_a1, en_b1, output reg signed [32:0] en_p1,
    // Two-deep chain on the B-path pre-adder: the 24-bit multiplicand
    // does not fit B, so the sum goes there.
    input signed [7:0] bs_d, bs_a, input signed [23:0] bs_w, output signed [32:0] bs_p,
    // Two-deep chain with its own enable, in a cell with four enables.
    input ce_en_d, input ce_en_a, input ce_en_b, input ce_en_p,
    input signed [15:0] ce_d, ce_a, ce_b, output reg signed [32:0] ce_p
);
  reg signed [16:0] ad_ad, ad_wad, dr_ad3, dr_ad4, dr_ad5;
  reg signed [15:0] dr_d1s0, dr_d2s0, dr_d2s1, dr_d4s0, dr_d5s0, dr_d5s1;
  reg signed [15:0] as_ds0, as_ds1, as_as0;
  reg signed [15:0] en_d0q, en_d1q, en_a1q, en_b1q;
  reg signed [7:0]  bs_q0, bs_q1;
  reg signed [15:0] ce_dq0, ce_dq1, ce_aq, ce_bq;

  assign ad_p  = ad_ad * ad_b;
  assign ad_wp = ad_wad * ad_wb;
  assign dr_p0 = (dr_d0 + dr_a0) * dr_b0;
  assign dr_p1 = (dr_d1s0 + dr_a1) * dr_b1;
  assign dr_p2 = (dr_d2s1 + dr_a2) * dr_b2;
  assign dr_p3 = dr_ad3 * dr_b3;
  assign dr_p4 = dr_ad4 * dr_b4;
  assign dr_p5 = dr_ad5 * dr_b5;
  assign as_p  = (as_ds1 + as_as0) * as_b;
  assign en_p0 = (en_d0q + en_a0) * en_b0;
  assign bs_p  = (bs_q1 + bs_a) * bs_w;

  always @(posedge clk) begin
    ad_ad   <= ad_d + ad_a;
    ad_wad  <= ad_wd + ad_wa;
    dr_d1s0 <= dr_d1;
    dr_d2s0 <= dr_d2;
    dr_d2s1 <= dr_d2s0;
    dr_d4s0 <= dr_d4;
    dr_d5s0 <= dr_d5;
    dr_d5s1 <= dr_d5s0;
    dr_ad3  <= dr_d3 + dr_a3;
    dr_ad4  <= dr_d4s0 + dr_a4;
    dr_ad5  <= dr_d5s1 + dr_a5;
    as_ds0  <= as_d;
    as_ds1  <= as_ds0;
    as_as0  <= as_a;
    if (en0)  en_d0q <= en_d0;
    if (en_d) en_d1q <= en_d1;
    if (en_a) en_a1q <= en_a1;
    if (en_b) en_b1q <= en_b1;
    if (en_p) en_p1  <= (en_d1q + en_a1q) * en_b1q;
    bs_q0   <= bs_d;
    bs_q1   <= bs_q0;
    if (ce_en_d) ce_dq0 <= ce_d;
    if (ce_en_d) ce_dq1 <= ce_dq0;
    if (ce_en_a) ce_aq  <= ce_a;
    if (ce_en_b) ce_bq  <= ce_b;
    if (ce_en_p) ce_p   <= (ce_dq1 + ce_aq) * ce_bq;
  end
endmodule
