// RTL against netlist every cycle (!== so x mismatches); every 4th cycle uses extreme operands.
`timescale 1ns/1ps

module tb;
  reg clk = 0, rst = 1;
  reg signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3;
  reg [16:0] u0, u1, u2, u3;
  reg signed [15:0] h0, h1, h2, h3, h4, h5;
  reg signed [29:0] w0, w1;
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

  wire signed [36:0] sub_rtl_pr, sub_syn_pr, sub_rtl_pi, sub_syn_pi;
  dspv4_link_sub     sub_rtl (.ar(a0), .ai(a1), .br(b0), .bi(b1), .cr(a2), .ci(b2), .pr(sub_rtl_pr), .pi(sub_rtl_pi));
  dspv4_link_sub_syn sub_syn (.ar(a0), .ai(a1), .br(b0), .bi(b1), .cr(a2), .ci(b2), .pr(sub_syn_pr), .pi(sub_syn_pi));

  wire [33:0] zero_t_rtl, zero_t_syn;
  wire [34:0] zero_p_rtl, zero_p_syn;
  dspv4_link_zero     zero_rtl (.a0(u0), .b0(u1), .a1(u2), .b1(u3), .t(zero_t_rtl), .p(zero_p_rtl));
  dspv4_link_zero_syn zero_syn (.a0(u0), .b0(u1), .a1(u2), .b1(u3), .t(zero_t_syn), .p(zero_p_syn));

  wire signed [36:0] pa_t_rtl, pa_t_syn;
  wire signed [37:0] pa_p_rtl, pa_p_syn;
  dspv4_link_preadd_a     pa_rtl (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pa_t_rtl), .p(pa_p_rtl));
  dspv4_link_preadd_a_syn pa_syn (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pa_t_syn), .p(pa_p_syn));

  wire signed [36:0] pas_t_rtl, pas_t_syn;
  wire signed [37:0] pas_p_rtl, pas_p_syn;
  dspv4_link_preadd_a_sub     pas_rtl (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pas_t_rtl), .p(pas_p_rtl));
  dspv4_link_preadd_a_sub_syn pas_syn (.d0(a2), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(pas_t_syn), .p(pas_p_syn));

  wire signed [46:0] pb_t_rtl, pb_t_syn;
  wire signed [47:0] pb_p_rtl, pb_p_syn;
  dspv4_link_preadd_b     pb_rtl (.d0(h0), .b0(h1), .a0(w0), .a1(a1), .b1(b1), .t(pb_t_rtl), .p(pb_p_rtl));
  dspv4_link_preadd_b_syn pb_syn (.d0(h0), .b0(h1), .a0(w0), .a1(a1), .b1(b1), .t(pb_t_syn), .p(pb_p_syn));

  wire signed [46:0] pbs_t_rtl, pbs_t_syn;
  wire signed [47:0] pbs_p_rtl, pbs_p_syn;
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

  wire signed [48:0] pbsc_p_rtl, pbsc_p_syn;
  dspv4_link_preadd_b_sub_chain     pbsc_rtl (.d0(h0), .b0(h1), .d1(h2), .b1(h3), .a0(w0), .a1(w1), .a2(a2), .b2(b2), .p(pbsc_p_rtl));
  dspv4_link_preadd_b_sub_chain_syn pbsc_syn (.d0(h0), .b0(h1), .d1(h2), .b1(h3), .a0(w0), .a1(w1), .a2(a2), .b2(b2), .p(pbsc_p_syn));

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
    if (i % 4 == 0) begin
      a0 = extreme($random); b0 = extreme($random); a1 = extreme($random); b1 = extreme($random);
      a2 = extreme($random); b2 = extreme($random); a3 = extreme($random); b3 = extreme($random);
      u0 = extreme_unsigned($random); u1 = extreme_unsigned($random);
      u2 = extreme_unsigned($random); u3 = extreme_unsigned($random);
      h0 = extreme16($random); h1 = extreme16($random); h2 = extreme16($random);
      h3 = extreme16($random); h4 = extreme16($random); h5 = extreme16($random);
      w0 = extreme30($random); w1 = extreme30($random);
    end else begin
      a0 = $random; b0 = $random; a1 = $random; b1 = $random;
      a2 = $random; b2 = $random; a3 = $random; b3 = $random;
      u0 = $random; u1 = $random; u2 = $random; u3 = $random;
      h0 = $random; h1 = $random; h2 = $random; h3 = $random; h4 = $random; h5 = $random;
      w0 = $random; w1 = $random;
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
      check("sub.pr", sub_rtl_pr, sub_syn_pr);
      check("sub.pi", sub_rtl_pi, sub_syn_pi);
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
    end
    $display("RESULT: %0d mismatches in 2000 cycles", bad);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
