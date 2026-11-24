// RTL against netlist every cycle (!== so x mismatches); every 4th cycle uses extreme operands;
// reset every 50th cycle.
`timescale 1ns/1ps

module tb;
  reg clk = 0, rst = 1;
  reg signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3, a4, b4;
  reg [16:0] u0, u1, u2, u3;
  reg signed [15:0] h0, h1, h2, h3, h4, h5;
  reg signed [29:0] w0, w1;
  reg [15:0] x16;
  reg [107:0] xy;
  reg [9:0] x10;
  reg signed [3:0] c4;
  integer i, bad = 0;

  wire signed [35:0] small_t_rtl, small_t_syn;
  wire signed [36:0] small_p_rtl, small_p_syn;
  dspv4_link_small     small_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(small_t_rtl), .p(small_p_rtl));
  dspv4_link_small_syn small_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(small_t_syn), .p(small_p_syn));

  wire signed [37:0] chain_rtl_p, chain_syn_p;
  dspv4_link_chain     chain_rtl (.a1(a0), .b1(b0), .a2(a1), .b2(b1), .a3(a2), .b3(b2), .a4(a3), .b4(b3), .p(chain_rtl_p));
  dspv4_link_chain_syn chain_syn (.a1(a0), .b1(b0), .a2(a1), .b2(b1), .a3(a2), .b3(b2), .a4(a3), .b4(b3), .p(chain_syn_p));

  wire signed [37:0] reversed_rtl_p, reversed_syn_p;
  dspv4_link_chain_reversed     reversed_rtl (.a1(a0), .b1(b0), .a2(a1), .b2(b1), .a3(a2), .b3(b2), .a4(a3), .b4(b3), .p(reversed_rtl_p));
  dspv4_link_chain_reversed_syn reversed_syn (.a1(a0), .b1(b0), .a2(a1), .b2(b1), .a3(a2), .b3(b2), .a4(a3), .b4(b3), .p(reversed_syn_p));

  wire signed [37:0] registered_rtl_y, registered_syn_y;
  dspv4_link_registered     registered_rtl (.clk(clk), .rst(rst), .x(a0), .y(registered_rtl_y));
  dspv4_link_registered_syn registered_syn (.clk(clk), .rst(rst), .x(a0), .y(registered_syn_y));

  wire signed [37:0] sub_rtl_p, sub_syn_p, sub_rtl_q, sub_syn_q;
  dspv4_link_sub     sub_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .a2(a2), .b2(b2), .a3(a3), .b3(b3), .a4(a4), .b4(b4), .p(sub_rtl_p), .q(sub_rtl_q));
  dspv4_link_sub_syn sub_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .a2(a2), .b2(b2), .a3(a3), .b3(b3), .a4(a4), .b4(b4), .p(sub_syn_p), .q(sub_syn_q));

  wire [33:0] zero_t_rtl, zero_t_syn;
  wire [34:0] zero_p_rtl, zero_p_syn;
  dspv4_link_zero     zero_rtl (.a0(u0), .b0(u1), .a1(u2), .b1(u3), .t(zero_t_rtl), .p(zero_p_rtl));
  dspv4_link_zero_syn zero_syn (.a0(u0), .b0(u1), .a1(u2), .b1(u3), .t(zero_t_syn), .p(zero_p_syn));

  wire signed [36:0] pa_t_rtl, pa_t_syn;
  wire signed [37:0] pa_p_rtl, pa_p_syn;
  dspv4_link_preadd_a     pa_rtl (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pa_t_rtl), .p(pa_p_rtl));
  dspv4_link_preadd_a_syn pa_syn (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pa_t_syn), .p(pa_p_syn));

  wire signed [35:0] pas_t_rtl, pas_t_syn;
  wire signed [36:0] pas_p_rtl, pas_p_syn;
  dspv4_link_preadd_a_sub     pas_rtl (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pas_t_rtl), .p(pas_p_rtl));
  dspv4_link_preadd_a_sub_syn pas_syn (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pas_t_syn), .p(pas_p_syn));

  wire signed [46:0] pb_t_rtl, pb_t_syn;
  wire signed [47:0] pb_p_rtl, pb_p_syn;
  dspv4_link_preadd_b     pb_rtl (.d0(h0), .b0(h1), .a0(w0), .a1(a1), .b1(b1), .t(pb_t_rtl), .p(pb_p_rtl));
  dspv4_link_preadd_b_syn pb_syn (.d0(h0), .b0(h1), .a0(w0), .a1(a1), .b1(b1), .t(pb_t_syn), .p(pb_p_syn));

  wire signed [45:0] pbs_t_rtl, pbs_t_syn;
  wire signed [46:0] pbs_p_rtl, pbs_p_syn;
  dspv4_link_preadd_b_sub     pbs_rtl (.d0(h0), .b0(h1), .a0(w0), .a1(a1), .b1(b1), .t(pbs_t_rtl), .p(pbs_p_rtl));
  dspv4_link_preadd_b_sub_syn pbs_syn (.d0(h0), .b0(h1), .a0(w0), .a1(a1), .b1(b1), .t(pbs_t_syn), .p(pbs_p_syn));

  wire signed [36:0] pac_p_rtl, pac_p_syn;
  dspv4_link_preadd_a_chain     pac_rtl (.z0(h0), .z7(h1), .z1(h2), .z6(h3), .k0(h4), .k1(h5), .a2(a2), .b2(b2), .p(pac_p_rtl));
  dspv4_link_preadd_a_chain_syn pac_syn (.z0(h0), .z7(h1), .z1(h2), .z6(h3), .k0(h4), .k1(h5), .a2(a2), .b2(b2), .p(pac_p_syn));

  wire signed [36:0] pasc_p_rtl, pasc_p_syn;
  dspv4_link_preadd_a_sub_chain     pasc_rtl (.z0(h0), .z7(h1), .z1(h2), .z6(h3), .k0(h4), .k1(h5), .a2(a2), .b2(b2), .p(pasc_p_rtl));
  dspv4_link_preadd_a_sub_chain_syn pasc_syn (.z0(h0), .z7(h1), .z1(h2), .z6(h3), .k0(h4), .k1(h5), .a2(a2), .b2(b2), .p(pasc_p_syn));

  wire signed [48:0] pbc_p_rtl, pbc_p_syn;
  dspv4_link_preadd_b_chain     pbc_rtl (.d0(h0), .b0(h1), .d1(h2), .b1(h3), .a0(w0), .a1(w1), .a2(a2), .b2(b2), .p(pbc_p_rtl));
  dspv4_link_preadd_b_chain_syn pbc_syn (.d0(h0), .b0(h1), .d1(h2), .b1(h3), .a0(w0), .a1(w1), .a2(a2), .b2(b2), .p(pbc_p_syn));

  wire signed [47:0] pbsc_p_rtl, pbsc_p_syn;
  dspv4_link_preadd_b_sub_chain     pbsc_rtl (.d0(h0), .b0(h1), .d1(h2), .b1(h3), .a0(w0), .a1(w1), .a2(a2), .b2(b2), .p(pbsc_p_rtl));
  dspv4_link_preadd_b_sub_chain_syn pbsc_syn (.d0(h0), .b0(h1), .d1(h2), .b1(h3), .a0(w0), .a1(w1), .a2(a2), .b2(b2), .p(pbsc_p_syn));

  wire signed [32:0] xa_t_rtl, xa_t_syn;
  wire signed [33:0] xa_p_rtl, xa_p_syn;
  dspv4_link_xpath_a     xa_rtl (.a0(h0), .d0(h1), .a1(a1), .b1(b1), .t(xa_t_rtl), .p(xa_p_rtl));
  dspv4_link_xpath_a_syn xa_syn (.a0(h0), .d0(h1), .a1(a1), .b1(b1), .t(xa_t_syn), .p(xa_p_syn));

  wire signed [36:0] xb_t_rtl, xb_t_syn;
  wire signed [37:0] xb_p_rtl, xb_p_syn;
  dspv4_link_xpath_b     xb_rtl (.a0(a0), .d0(a2), .a1(a1), .b1(b1), .t(xb_t_rtl), .p(xb_p_rtl));
  dspv4_link_xpath_b_syn xb_syn (.a0(a0), .d0(a2), .a1(a1), .b1(b1), .t(xb_t_syn), .p(xb_p_syn));

  wire signed [32:0] top_t_rtl, top_t_syn;
  wire signed [33:0] top_p_rtl, top_p_syn;
  dspv4_link_top_edge     top_rtl (.x(x16), .a1(a1), .b1(b1), .t(top_t_rtl), .p(top_p_rtl));
  dspv4_link_top_edge_syn top_syn (.x(x16), .a1(a1), .b1(b1), .t(top_t_syn), .p(top_p_syn));

  wire signed [32:0] bottom_t_rtl, bottom_t_syn;
  wire signed [33:0] bottom_p_rtl, bottom_p_syn;
  dspv4_link_bottom_edge     bottom_rtl (.x(x16), .a1(a1), .b1(b1), .t(bottom_t_rtl), .p(bottom_p_rtl));
  dspv4_link_bottom_edge_syn bottom_syn (.x(x16), .a1(a1), .b1(b1), .t(bottom_t_syn), .p(bottom_p_syn));

  wire [31:0] utop_t_rtl, utop_t_syn;
  wire [34:0] utop_p_rtl, utop_p_syn;
  dspv4_link_unsigned_top_edge     utop_rtl (.x(x16), .a1(u2), .b1(u3), .t(utop_t_rtl), .p(utop_p_rtl));
  dspv4_link_unsigned_top_edge_syn utop_syn (.x(x16), .a1(u2), .b1(u3), .t(utop_t_syn), .p(utop_p_syn));

  wire signed [36:0] two_p_rtl, two_p_syn, two_q_rtl, two_q_syn;
  dspv4_link_two_consumers     two_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .a2(a2), .b2(b2), .p(two_p_rtl), .q(two_q_rtl));
  dspv4_link_two_consumers_syn two_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .a2(a2), .b2(b2), .p(two_p_syn), .q(two_q_syn));

  wire signed [35:0] inst_t_rtl, inst_t_syn;
  wire signed [36:0] inst_p_rtl, inst_p_syn;
  dspv4_link_instance     inst_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(inst_t_rtl), .p(inst_p_rtl));
  dspv4_link_instance_syn inst_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(inst_t_syn), .p(inst_p_syn));

  wire signed [34:0] cc_t_rtl, cc_t_syn;
  wire signed [35:0] cc_p_rtl, cc_p_syn;
  dspv4_link_constant_c     cc_rtl (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(cc_t_rtl), .p(cc_p_rtl));
  dspv4_link_constant_c_syn cc_syn (.a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(cc_t_syn), .p(cc_p_syn));

  wire signed [36:0] un_p1_rtl, un_p1_syn, un_p2_rtl, un_p2_syn, un_p3_rtl, un_p3_syn;
  dspv4_link_unregistered     un_rtl (.clk(clk), .rst(rst), .xy(xy), .p1(un_p1_rtl), .p2(un_p2_rtl), .p3(un_p3_rtl));
  dspv4_link_unregistered_syn un_syn (.clk(clk), .rst(rst), .xy(xy), .p1(un_p1_syn), .p2(un_p2_syn), .p3(un_p3_syn));

  wire signed [36:0] reset_p_rtl, reset_p_syn;
  dspv4_link_reset     reset_rtl (.clk(clk), .rst(rst), .x(x10), .c(c4), .a1(a1), .b1(b1), .p(reset_p_rtl));
  dspv4_link_reset_syn reset_syn (.clk(clk), .rst(rst), .x(x10), .c(c4), .a1(a1), .b1(b1), .p(reset_p_syn));

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

  function [16:0] extreme_unsigned(input integer choice);
    extreme_unsigned = choice[0] ? 17'h1ffff : 17'h0;
  endfunction

  function signed [15:0] extreme16(input integer choice);
    extreme16 = choice[0] ? 16'sh8000 : 16'sh7fff;
  endfunction

  function signed [29:0] extreme30(input integer choice);
    extreme30 = choice[0] ? 30'sh20000000 : 30'sh1fffffff;
  endfunction

  task drive;
    xy = {$random, $random, $random, $random}; x10 = $random; c4 = $random;
    rst = (i % 50 == 0);
    if (i % 4 == 0) begin
      a0 = extreme($random); b0 = extreme($random); a1 = extreme($random); b1 = extreme($random);
      a2 = extreme($random); b2 = extreme($random); a3 = extreme($random); b3 = extreme($random);
      a4 = extreme($random); b4 = extreme($random);
      u0 = extreme_unsigned($random); u1 = extreme_unsigned($random);
      u2 = extreme_unsigned($random); u3 = extreme_unsigned($random);
      h0 = extreme16($random); h1 = extreme16($random); h2 = extreme16($random);
      h3 = extreme16($random); h4 = extreme16($random); h5 = extreme16($random);
      w0 = extreme30($random); w1 = extreme30($random);
      x16 = $random & 1 ? 16'hffff : 16'h0;
    end else begin
      a0 = $random; b0 = $random; a1 = $random; b1 = $random;
      a2 = $random; b2 = $random; a3 = $random; b3 = $random; a4 = $random; b4 = $random;
      u0 = $random; u1 = $random; u2 = $random; u3 = $random;
      h0 = $random; h1 = $random; h2 = $random; h3 = $random; h4 = $random; h5 = $random;
      w0 = $random; w1 = $random; x16 = $random;
    end
  endtask

  initial begin
    i = 0;
    drive;
    @(posedge clk); rst = #1 0;
    for (i = 0; i < 2000; i = i + 1) begin
      drive;
      @(posedge clk); #1;
      check("small.t", small_t_rtl, small_t_syn);
      check("small.p", small_p_rtl, small_p_syn);
      check("chain.p", chain_rtl_p, chain_syn_p);
      check("chain_reversed.p", reversed_rtl_p, reversed_syn_p);
      check("registered.y", registered_rtl_y, registered_syn_y);
      check("sub.p", sub_rtl_p, sub_syn_p);
      check("sub.q", sub_rtl_q, sub_syn_q);
      check("zero.t", zero_t_rtl, zero_t_syn);
      check("zero.p", zero_p_rtl, zero_p_syn);
      check("preadd_a.t", pa_t_rtl, pa_t_syn);
      check("preadd_a.p", pa_p_rtl, pa_p_syn);
      check("preadd_a_sub.t", pas_t_rtl, pas_t_syn);
      check("preadd_a_sub.p", pas_p_rtl, pas_p_syn);
      check("preadd_b.t", pb_t_rtl, pb_t_syn);
      check("preadd_b.p", pb_p_rtl, pb_p_syn);
      check("preadd_b_sub.t", pbs_t_rtl, pbs_t_syn);
      check("preadd_b_sub.p", pbs_p_rtl, pbs_p_syn);
      check("preadd_a_chain.p", pac_p_rtl, pac_p_syn);
      check("preadd_a_sub_chain.p", pasc_p_rtl, pasc_p_syn);
      check("preadd_b_chain.p", pbc_p_rtl, pbc_p_syn);
      check("preadd_b_sub_chain.p", pbsc_p_rtl, pbsc_p_syn);
      check("xpath_a.t", xa_t_rtl, xa_t_syn);
      check("xpath_a.p", xa_p_rtl, xa_p_syn);
      check("xpath_b.t", xb_t_rtl, xb_t_syn);
      check("xpath_b.p", xb_p_rtl, xb_p_syn);
      check("top_edge.t", top_t_rtl, top_t_syn);
      check("top_edge.p", top_p_rtl, top_p_syn);
      check("bottom_edge.t", bottom_t_rtl, bottom_t_syn);
      check("bottom_edge.p", bottom_p_rtl, bottom_p_syn);
      check("unsigned_top_edge.t", utop_t_rtl, utop_t_syn);
      check("unsigned_top_edge.p", utop_p_rtl, utop_p_syn);
      check("two_consumers.p", two_p_rtl, two_p_syn);
      check("two_consumers.q", two_q_rtl, two_q_syn);
      check("instance.t", inst_t_rtl, inst_t_syn);
      check("instance.p", inst_p_rtl, inst_p_syn);
      check("constant_c.t", cc_t_rtl, cc_t_syn);
      check("constant_c.p", cc_p_rtl, cc_p_syn);
      check("unregistered.p1", un_p1_rtl, un_p1_syn);
      check("unregistered.p2", un_p2_rtl, un_p2_syn);
      check("unregistered.p3", un_p3_rtl, un_p3_syn);
      check("reset.p", reset_p_rtl, reset_p_syn);
    end
    $display("RESULT: %0d mismatches in 2000 cycles", bad);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
