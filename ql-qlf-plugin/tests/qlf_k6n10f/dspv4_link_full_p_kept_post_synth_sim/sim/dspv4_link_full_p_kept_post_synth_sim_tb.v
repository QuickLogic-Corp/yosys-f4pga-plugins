// RTL against netlist every cycle (!== so x mismatches); every 4th cycle uses extreme operands.
`timescale 1ns/1ps

module tb;
  reg clk = 0, rst = 1;
  reg signed [17:0] a0, b0, a1, b1, d0;
  reg signed [35:0] c;
  integer i, bad = 0;

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

  wire signed [36:0] acc_p_rtl, acc_p_syn;
  dspv4_link_kept_acc     acc_rtl (.clk(clk), .rst(rst), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .p(acc_p_rtl));
  dspv4_link_kept_acc_syn acc_syn (.clk(clk), .rst(rst), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .p(acc_p_syn));

  wire signed [35:0] preadd_t_rtl, preadd_t_syn;
  wire signed [36:0] preadd_p_rtl, preadd_p_syn;
  dspv4_link_kept_preadd     preadd_rtl (.d0(d0), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(preadd_t_rtl), .p(preadd_p_rtl));
  dspv4_link_kept_preadd_syn preadd_syn (.d0(d0), .a0(a0), .b0(b0), .a1(a1), .b1(b1), .t(preadd_t_syn), .p(preadd_p_syn));

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
    if (i % 4 == 0) begin
      a0 = extreme($random); b0 = extreme($random); a1 = extreme($random); b1 = extreme($random);
      d0 = extreme($random);
      c = $random & 1 ? 36'sh800000000 : 36'sh7ffffffff;
    end else begin
      a0 = $random; b0 = $random; a1 = $random; b1 = $random; d0 = $random;
      c = {$random, $random};
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
      check("acc.p", acc_p_rtl, acc_p_syn);
      check("preadd.t", preadd_t_rtl, preadd_t_syn);
      check("preadd.p", preadd_p_rtl, preadd_p_syn);
    end
    $display("RESULT: %0d mismatches in 2000 cycles", bad);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
