// Runs each RTL module beside its synthesised netlist on the same random
// stimulus and compares every output every cycle. Both resets are pulsed,
// each on about 1 cycle in 8: a register on the wrong reset, or a stage
// computed a cycle early, shows only when they fire.
`timescale 1ns/1ps

module tb;
  reg clk = 0, rstn = 0, rst2n = 0;
  reg signed [15:0] a, b;
  reg signed [33:0] c;
  integer i, bad = 0, rstn_hits = 0, rst2n_hits = 0;

  wire signed [34:0] p0_rtl, p0_syn;
  dspv4_mreg_rst_add     u0_rtl (.clk(clk), .rstn(rstn), .rst2n(rst2n), .a(a), .b(b), .c(c), .p(p0_rtl));
  dspv4_mreg_rst_add_syn u0_syn (.clk(clk), .rstn(rstn), .rst2n(rst2n), .a(a), .b(b), .c(c), .p(p0_syn));

  wire signed [31:0] p1_rtl, p1_syn;
  dspv4_mreg_rst_out     u1_rtl (.clk(clk), .rstn(rstn), .rst2n(rst2n), .a(a), .b(b), .p(p1_rtl));
  dspv4_mreg_rst_out_syn u1_syn (.clk(clk), .rstn(rstn), .rst2n(rst2n), .a(a), .b(b), .p(p1_syn));

  always #5 clk = ~clk;

  task check(input [255:0] name, input [34:0] rtl, input [34:0] syn);
    if (rtl !== syn) begin
      bad = bad + 1;
      if (bad <= 10) $display("MISMATCH cycle %0d %0s: rtl=%0d syn=%0d", i, name, rtl, syn);
    end
  endtask

  // The first 8 cycles hold both resets, so every register starts defined.
  initial begin
    a = 0; b = 0; c = 0;
    for (i = 0; i < 2000; i = i + 1) begin
      rstn  = (i >= 8) && ($urandom % 8 != 0);
      rst2n = (i >= 8) && ($urandom % 8 != 0);
      if (i >= 8 && !rstn)  rstn_hits = rstn_hits + 1;
      if (i >= 8 && !rst2n) rst2n_hits = rst2n_hits + 1;
      a = $random; b = $random; c = {$random, $random};
      @(posedge clk); #1;
      if (i >= 8) begin
        check("mreg_rst_add.p", p0_rtl, p0_syn);
        check("mreg_rst_out.p", {{3{p1_rtl[31]}}, p1_rtl}, {{3{p1_syn[31]}}, p1_syn});
      end
    end
    $display("RESULT: %0d mismatches in 1992 cycles; rstn asserted on %0d, rst2n on %0d",
             bad, rstn_hits, rst2n_hits);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
