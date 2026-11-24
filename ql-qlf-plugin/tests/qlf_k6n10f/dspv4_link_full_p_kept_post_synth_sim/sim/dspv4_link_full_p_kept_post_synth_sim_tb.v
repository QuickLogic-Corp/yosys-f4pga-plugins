// RTL against netlist every cycle (!== so x mismatches); every 4th cycle uses extreme operands;
// reset every 50th cycle.
`timescale 1ns/1ps

module tb;
  reg clk = 0, rst = 1;
  reg signed [17:0] a0, b0, a1, b1, d0;
  reg signed [35:0] c;
  reg [9:0] x;
  reg signed [3:0] c4;
  reg [16:0] u1, u2;
  reg [15:0] x16;
  reg signed [31:0] w32;
  reg signed [48:0] c49;
  reg [323:0] xy;
  reg signed [15:0] h0, h1;
  reg signed [29:0] w30;
  reg signed [5:0] x6;
  integer i, k, bad = 0;

  wire signed [29:0] trunc_t_rtl, trunc_t_syn;
  wire signed [36:0] trunc_p_rtl, trunc_p_syn;
  dspv4_link_kept_trunc     trunc_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(trunc_t_rtl), .p(trunc_p_rtl));
  dspv4_link_kept_trunc_syn trunc_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(trunc_t_syn), .p(trunc_p_syn));

  wire signed [36:0] wrap_p_rtl, wrap_p_syn;
  dspv4_link_kept_wrap     wrap_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .c(c), .p(wrap_p_rtl));
  dspv4_link_kept_wrap_syn wrap_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .c(c), .p(wrap_p_syn));

  wire signed [36:0] zext_p_rtl, zext_p_syn;
  dspv4_link_kept_zext     zext_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .p(zext_p_rtl));
  dspv4_link_kept_zext_syn zext_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .p(zext_p_syn));

  wire signed [35:0] acc_t_rtl, acc_t_syn;
  wire signed [36:0] acc_p_rtl, acc_p_syn;
  dspv4_link_kept_acc     acc_rtl (.clk(clk), .rst(rst), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(acc_t_rtl), .p(acc_p_rtl));
  dspv4_link_kept_acc_syn acc_syn (.clk(clk), .rst(rst), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(acc_t_syn), .p(acc_p_syn));

  wire signed [35:0] preadd_t_rtl, preadd_t_syn;
  wire signed [36:0] preadd_p_rtl, preadd_p_syn;
  dspv4_link_kept_preadd     preadd_rtl (.d0(d0), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(preadd_t_rtl), .p(preadd_p_rtl));
  dspv4_link_kept_preadd_syn preadd_syn (.d0(d0), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(preadd_t_syn), .p(preadd_p_syn));

  wire [36:0] reset_p_rtl, reset_p_syn;
  dspv4_link_kept_reset     reset_rtl (.clk(clk), .rst(rst), .x(x), .c(c4), .a1(u1), .b1(u2), .p(reset_p_rtl));
  dspv4_link_kept_reset_syn reset_syn (.clk(clk), .rst(rst), .x(x), .c(c4), .a1(u1), .b1(u2), .p(reset_p_syn));

  wire signed [39:0] loop_y_rtl, loop_y_syn, loop_z_rtl, loop_z_syn;
  dspv4_link_kept_loop     loop_rtl (.clk(clk), .rst(rst), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .y(loop_y_rtl), .z(loop_z_rtl));
  dspv4_link_kept_loop_syn loop_syn (.clk(clk), .rst(rst), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .y(loop_y_syn), .z(loop_z_syn));

  wire signed [32:0] top_t_rtl, top_t_syn;
  wire signed [33:0] top_p_rtl, top_p_syn;
  dspv4_link_kept_top_edge     top_rtl (.x(x16), .a1(a1), .b1(b1), .t(top_t_rtl), .p(top_p_rtl));
  dspv4_link_kept_top_edge_syn top_syn (.x(x16), .a1(a1), .b1(b1), .t(top_t_syn), .p(top_p_syn));

  wire signed [32:0] bottom_t_rtl, bottom_t_syn;
  wire signed [33:0] bottom_p_rtl, bottom_p_syn;
  dspv4_link_kept_bottom_edge     bottom_rtl (.x(x16), .a1(a1), .b1(b1), .t(bottom_t_rtl), .p(bottom_p_rtl));
  dspv4_link_kept_bottom_edge_syn bottom_syn (.x(x16), .a1(a1), .b1(b1), .t(bottom_t_syn), .p(bottom_p_syn));

  wire signed [48:0] exceed_t_rtl, exceed_t_syn;
  wire signed [49:0] exceed_p_rtl, exceed_p_syn;
  dspv4_link_kept_exceed     exceed_rtl (.a0(w32), .b0(b0), .c0(c49), .a1(a1), .b1(b1), .t(exceed_t_rtl), .p(exceed_p_rtl));
  dspv4_link_kept_exceed_syn exceed_syn (.a0(w32), .b0(b0), .c0(c49), .a1(a1), .b1(b1), .t(exceed_t_syn), .p(exceed_p_syn));

  wire signed [35:0] rss_t_rtl, rss_t_syn, acin_t_rtl, acin_t_syn, carry_t_rtl, carry_t_syn;
  wire signed [36:0] rss_p_rtl, rss_p_syn, acin_p_rtl, acin_p_syn, carry_p_rtl, carry_p_syn;
  dspv4_link_kept_rss       rss_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(rss_t_rtl), .p(rss_p_rtl));
  dspv4_link_kept_rss_syn   rss_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(rss_t_syn), .p(rss_p_syn));
  dspv4_link_kept_acin      acin_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(acin_t_rtl), .p(acin_p_rtl));
  dspv4_link_kept_acin_syn  acin_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(acin_t_syn), .p(acin_p_syn));
  dspv4_link_kept_carry     carry_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(carry_t_rtl), .p(carry_p_rtl));
  dspv4_link_kept_carry_syn carry_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(carry_t_syn), .p(carry_p_syn));

  wire signed [36:0] rz_rtl [1:7], rz_syn [1:7];
  dspv4_link_kept_register_zeros     rz_r (.clk(clk), .rst(rst), .xy(xy[251:0]), .p1(rz_rtl[1]), .p2(rz_rtl[2]), .p3(rz_rtl[3]),
                                           .p4(rz_rtl[4]), .p5(rz_rtl[5]), .p6(rz_rtl[6]), .p7(rz_rtl[7]));
  dspv4_link_kept_register_zeros_syn rz_s (.clk(clk), .rst(rst), .xy(xy[251:0]), .p1(rz_syn[1]), .p2(rz_syn[2]), .p3(rz_syn[3]),
                                           .p4(rz_syn[4]), .p5(rz_syn[5]), .p6(rz_syn[6]), .p7(rz_syn[7]));

  wire signed [45:0] pbs_t_rtl, pbs_t_syn;
  wire signed [46:0] pbs_p_rtl, pbs_p_syn;
  dspv4_link_kept_preadd_b_short     pbs_rtl (.d0(h0), .b0(h1), .a0(w30), .a1(a1), .b1(b1), .t(pbs_t_rtl), .p(pbs_p_rtl));
  dspv4_link_kept_preadd_b_short_syn pbs_syn (.d0(h0), .b0(h1), .a0(w30), .a1(a1), .b1(b1), .t(pbs_t_syn), .p(pbs_p_syn));

  wire signed [31:0] xas_t_rtl, xas_t_syn;
  wire signed [32:0] xas_p_rtl, xas_p_syn;
  dspv4_link_kept_xpath_a_short     xas_rtl (.a0(h0), .d0(h1), .a1(a1), .b1(b1), .t(xas_t_rtl), .p(xas_p_rtl));
  dspv4_link_kept_xpath_a_short_syn xas_syn (.a0(h0), .d0(h1), .a1(a1), .b1(b1), .t(xas_t_syn), .p(xas_p_syn));

  wire signed [35:0] xbs_t_rtl, xbs_t_syn;
  wire signed [36:0] xbs_p_rtl, xbs_p_syn;
  dspv4_link_kept_xpath_b_short     xbs_rtl (.a0(a0), .d0(d0), .a1(a1), .b1(b1), .t(xbs_t_rtl), .p(xbs_p_rtl));
  dspv4_link_kept_xpath_b_short_syn xbs_syn (.a0(a0), .d0(d0), .a1(a1), .b1(b1), .t(xbs_t_syn), .p(xbs_p_syn));

  wire signed [35:0] mx_t_rtl, mx_t_syn, ms_t_rtl, ms_t_syn, bc_t_rtl, bc_t_syn;
  wire signed [36:0] mx_p_rtl, mx_p_syn, ms_p_rtl, ms_p_syn, bc_p_rtl, bc_p_syn;
  dspv4_link_kept_mixed           mx_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .x(x6), .t(mx_t_rtl), .p(mx_p_rtl));
  dspv4_link_kept_mixed_syn       mx_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .x(x6), .t(mx_t_syn), .p(mx_p_syn));
  dspv4_link_kept_mixed_shift     ms_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(ms_t_rtl), .p(ms_p_rtl));
  dspv4_link_kept_mixed_shift_syn ms_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(ms_t_syn), .p(ms_p_syn));
  dspv4_link_kept_bcin            bc_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(bc_t_rtl), .p(bc_p_rtl));
  dspv4_link_kept_bcin_syn        bc_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(bc_t_syn), .p(bc_p_syn));

  always #5 clk = ~clk;

  task check(input [255:0] name, input [49:0] rtl, input [49:0] syn);
    if (rtl !== syn) begin
      bad = bad + 1;
      if (bad <= 10) $display("MISMATCH cycle %0d %0s: rtl=%0d syn=%0d", i, name, rtl, syn);
    end
  endtask

  function signed [17:0] extreme(input integer choice);
    extreme = choice[0] ? 18'sh20000 : 18'sh1ffff;
  endfunction

  task drive;
    x = $random; c4 = $random; u1 = $random; u2 = $random;
    xy = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random}; x6 = $random;
    rst = (i % 50 == 0);
    if (i % 4 == 0) begin
      a0 = extreme($random); b0 = extreme($random); a1 = extreme($random); b1 = extreme($random);
      d0 = extreme($random);
      c = $random & 1 ? 36'sh800000000 : 36'sh7ffffffff;
      x16 = $random & 1 ? 16'hffff : 16'h0;
      w32 = $random & 1 ? 32'sh80000000 : 32'sh7fffffff;
      c49 = $random & 1 ? 49'sh1000000000000 : 49'shffffffffffff;
      h0 = $random & 1 ? 16'sh8000 : 16'sh7fff; h1 = $random & 1 ? 16'sh8000 : 16'sh7fff;
      w30 = $random & 1 ? 30'sh20000000 : 30'sh1fffffff;
    end else begin
      a0 = $random; b0 = $random; a1 = $random; b1 = $random; d0 = $random;
      c = {$random, $random};
      x16 = $random; w32 = $random; c49 = {$random, $random};
      h0 = $random; h1 = $random; w30 = $random;
    end
  endtask

  initial begin
    i = 0;
    drive;
    @(posedge clk); rst = #1 0;
    for (i = 0; i < 2000; i = i + 1) begin
      drive;
      @(posedge clk); #1;
      check("trunc.t", trunc_t_rtl, trunc_t_syn);
      check("trunc.p", trunc_p_rtl, trunc_p_syn);
      check("wrap.p", wrap_p_rtl, wrap_p_syn);
      check("zext.p", zext_p_rtl, zext_p_syn);
      check("acc.t", acc_t_rtl, acc_t_syn);
      check("acc.p", acc_p_rtl, acc_p_syn);
      check("preadd.t", preadd_t_rtl, preadd_t_syn);
      check("preadd.p", preadd_p_rtl, preadd_p_syn);
      check("reset.p", reset_p_rtl, reset_p_syn);
      check("loop.y", loop_y_rtl, loop_y_syn);
      check("loop.z", loop_z_rtl, loop_z_syn);
      check("top_edge.t", top_t_rtl, top_t_syn);
      check("top_edge.p", top_p_rtl, top_p_syn);
      check("bottom_edge.t", bottom_t_rtl, bottom_t_syn);
      check("bottom_edge.p", bottom_p_rtl, bottom_p_syn);
      check("exceed.t", exceed_t_rtl, exceed_t_syn);
      check("exceed.p", exceed_p_rtl, exceed_p_syn);
      check("rss.t", rss_t_rtl, rss_t_syn);
      check("rss.p", rss_p_rtl, rss_p_syn);
      check("acin.t", acin_t_rtl, acin_t_syn);
      check("acin.p", acin_p_rtl, acin_p_syn);
      check("carry.t", carry_t_rtl, carry_t_syn);
      check("carry.p", carry_p_rtl, carry_p_syn);
      for (k = 1; k <= 7; k = k + 1)
        check("register_zeros.p", rz_rtl[k], rz_syn[k]);
      check("preadd_b_short.t", pbs_t_rtl, pbs_t_syn);
      check("preadd_b_short.p", pbs_p_rtl, pbs_p_syn);
      check("xpath_a_short.t", xas_t_rtl, xas_t_syn);
      check("xpath_a_short.p", xas_p_rtl, xas_p_syn);
      check("xpath_b_short.t", xbs_t_rtl, xbs_t_syn);
      check("xpath_b_short.p", xbs_p_rtl, xbs_p_syn);
      check("mixed.t", mx_t_rtl, mx_t_syn);
      check("mixed.p", mx_p_rtl, mx_p_syn);
      check("mixed_shift.t", ms_t_rtl, ms_t_syn);
      check("mixed_shift.p", ms_p_rtl, ms_p_syn);
      check("bcin.t", bc_t_rtl, bc_t_syn);
      check("bcin.p", bc_p_rtl, bc_p_syn);
    end
    $display("RESULT: %0d mismatches in 2000 cycles", bad);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
