// Every pre-adder shape whose registers the DSP is expected to ABSORB.
//
// Four groups, folded into one design because they all assert the same
// outcome: the pre-adder survives and no carry chain is left in fabric. The
// shapes that must be REFUSED live in their own tests -- mixing the two here
// would mean asserting totals, and a total cannot tell a fold that happened
// from a refusal that happened in its place.
//
//   ad_*  the pre-adder's output register, narrow and wide operands
//   dr_*  D and AD banks at every depth from 0 to 2
//   as_*  D deeper than A, so the banks absorb different amounts
//   en_*  clock enables, including one cell wanting more than the DSP routes
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
    input signed [15:0] en_d1, en_a1, en_b1, output reg signed [32:0] en_p1
);
  reg signed [16:0] ad_ad, ad_wad, dr_ad3, dr_ad4, dr_ad5;
  reg signed [15:0] dr_d1s0, dr_d2s0, dr_d2s1, dr_d4s0, dr_d5s0, dr_d5s1;
  reg signed [15:0] as_ds0, as_ds1, as_as0;
  reg signed [15:0] en_d0q, en_d1q, en_a1q, en_b1q;

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
  end
endmodule
