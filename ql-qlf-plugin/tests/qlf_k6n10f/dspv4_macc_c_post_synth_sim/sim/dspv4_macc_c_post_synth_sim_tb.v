// Runs each RTL module beside its synthesised netlist on the same random
// stimulus and compares every output every cycle. A compare with !== is
// deliberate: an undriven output is x, and x is the failure this test exists
// to catch.
`timescale 1ns/1ps

module tb;
  reg clk = 0, rst = 1;
  reg signed [17:0] a, b;
  reg signed [33:0] c;
  integer i, bad = 0;

  wire signed [49:0] p0_rtl, p0_syn;
  dspv4_macc_c            u0_rtl (.clk(clk), .rst(rst), .a(a), .b(b), .c(c), .p(p0_rtl));
  dspv4_macc_c_syn        u0_syn (.clk(clk), .rst(rst), .a(a), .b(b), .c(c), .p(p0_syn));

  wire signed [49:0] p1_rtl, p1_syn, q1_rtl, q1_syn;
  dspv4_macc_c_reader     u1_rtl (.clk(clk), .rst(rst), .a(a), .b(b), .c(c), .p(p1_rtl), .q(q1_rtl));
  dspv4_macc_c_reader_syn u1_syn (.clk(clk), .rst(rst), .a(a), .b(b), .c(c), .p(p1_syn), .q(q1_syn));

  wire signed [49:0] p2_rtl, p2_syn;
  dspv4_macc_c_self       u2_rtl (.clk(clk), .rst(rst), .a(a), .b(b), .p(p2_rtl));
  dspv4_macc_c_self_syn   u2_syn (.clk(clk), .rst(rst), .a(a), .b(b), .p(p2_syn));

  wire signed [35:0] p3_rtl, p3_syn;
  wire signed [17:0] q3_rtl, q3_syn;
  dspv4_mult_regin_port     u3_rtl (.clk(clk), .a(a), .b(b), .p(p3_rtl), .q(q3_rtl));
  dspv4_mult_regin_port_syn u3_syn (.clk(clk), .a(a), .b(b), .p(p3_syn), .q(q3_syn));

  always #5 clk = ~clk;

  task check(input [255:0] name, input [49:0] rtl, input [49:0] syn);
    if (rtl !== syn) begin
      bad = bad + 1;
      if (bad <= 10) $display("MISMATCH cycle %0d %0s: rtl=%0d syn=%0d", i, name, rtl, syn);
    end
  endtask

  initial begin
    a = 0; b = 0; c = 0;
    @(posedge clk); rst = #1 0;
    for (i = 0; i < 2000; i = i + 1) begin
      a = $random; b = $random; c = {$random, $random};
      @(posedge clk); #1;
      check("macc_c.p",         p0_rtl, p0_syn);
      check("macc_c_reader.p",  p1_rtl, p1_syn);
      check("macc_c_reader.q",  q1_rtl, q1_syn);
      check("macc_c_self.p",    p2_rtl, p2_syn);
      check("mult_regin_port.p", p3_rtl, p3_syn);
      check("mult_regin_port.q", q3_rtl, q3_syn);
    end
    $display("RESULT: %0d mismatches in 2000 cycles", bad);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
