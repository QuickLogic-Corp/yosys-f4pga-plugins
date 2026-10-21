// AD registers that carry a reset, and are ABSORBED into the AD bank.
//
// The AD bank's R pin is the cell's shared sync reset RSTN, the same one the
// D, A, B, C and M banks use (ffb preadd_path.v:117-127). So a resettable AD
// register goes in, as long as everything else in the cell on RSTN resets
// the same way.
//
//   lo  active-low reset: RSTN is the reset itself
//   hi  active-high reset: RSTN is its inverse
//   ch  D and B registers on the same reset join it in the cell
//   pr  a P register on a different reset: P is on ACCRSTN, not RSTN
//
// The shapes that must be refused are in dspv4_preadd_regs_refused, and the
// chains that are given up are in dspv4_preadd_adreg_evict.
module dspv4_preadd_adreg_rst (input clk, rstn, rst, rst2n,
                               input signed [15:0] lo_d, lo_a, lo_b, output signed [32:0] lo_p,
                               input signed [15:0] hi_d, hi_a, hi_b, output signed [32:0] hi_p,
                               input signed [15:0] ch_d, ch_a, ch_b, output signed [32:0] ch_p,
                               input signed [15:0] pr_d, pr_a, pr_b, output reg signed [32:0] pr_p);
  reg signed [16:0] lo_ad, hi_ad, ch_ad, pr_ad;
  reg signed [15:0] ch_dq, ch_bq;
  assign lo_p = lo_ad * lo_b;
  assign hi_p = hi_ad * hi_b;
  assign ch_p = ch_ad * ch_bq;
  always @(posedge clk) begin
    if (!rstn) lo_ad <= 0;
    else       lo_ad <= lo_d + lo_a;
    if (rst)   hi_ad <= 0;
    else       hi_ad <= hi_d + hi_a;
    if (!rstn) ch_dq <= 0;
    else       ch_dq <= ch_d;
    if (!rstn) ch_ad <= 0;
    else       ch_ad <= ch_dq + ch_a;
    if (!rstn) ch_bq <= 0;
    else       ch_bq <= ch_b;
    if (!rstn) pr_ad <= 0;
    else       pr_ad <= pr_d + pr_a;
    if (!rst2n) pr_p <= 0;
    else        pr_p <= pr_ad * pr_b;
  end
endmodule
