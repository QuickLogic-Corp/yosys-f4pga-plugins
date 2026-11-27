// Runs each RTL module beside its synthesised netlist on the same inputs and
// compares the outputs: first every input all ones, then 3000 random vectors.
// A dropped top bit shows only when that bit is 1, so about half the vectors
// see it. Mismatches are counted per design.
`timescale 1ns/1ps

module tb;
  reg [15:0] a, d, b;
  reg [19:0] b20;
  reg [7:0] a8;
  integer i, bad = 0;
  integer bad_design [1:4];

  wire [32:0] p1_rtl, p1_syn;
  dspv4_operand_ext_ona     u1_rtl (.a(a), .b(b), .p(p1_rtl));
  dspv4_operand_ext_ona_syn u1_syn (.a(a), .b(b), .p(p1_syn));

  wire [33:0] p2_rtl, p2_syn;
  dspv4_operand_ext_two     u2_rtl (.a(a), .b(b), .p(p2_rtl));
  dspv4_operand_ext_two_syn u2_syn (.a(a), .b(b), .p(p2_syn));

  wire [36:0] p3_rtl, p3_syn;
  dspv4_operand_ext_onb     u3_rtl (.a(a), .b(b20), .p(p3_rtl));
  dspv4_operand_ext_onb_syn u3_syn (.a(a), .b(b20), .p(p3_syn));

  wire [34:0] p4_rtl, p4_syn;
  dspv4_operand_ext_ond     u4_rtl (.d(d), .a(a8), .b(b), .p(p4_rtl));
  dspv4_operand_ext_ond_syn u4_syn (.d(d), .a(a8), .b(b), .p(p4_syn));

  task check(input integer which, input [255:0] name, input [36:0] rtl, input [36:0] syn);
    if (rtl !== syn) begin
      bad = bad + 1;
      bad_design[which] = bad_design[which] + 1;
      if (bad <= 10) $display("MISMATCH vector %0d %0s: rtl=%0d syn=%0d", i, name, rtl, syn);
    end
  endtask

  initial begin
    for (i = 1; i <= 4; i = i + 1) bad_design[i] = 0;
    for (i = 0; i <= 3000; i = i + 1) begin
      if (i == 0) begin a = 16'hffff; d = 16'hffff; b = 16'hffff; b20 = 20'hfffff; a8 = 8'hff; end
      else begin a = $random; d = $random; b = $random; b20 = $random; a8 = $random; end
      #1;
      check(1, "ona.p", p1_rtl, p1_syn);
      check(2, "two.p", p2_rtl, p2_syn);
      check(3, "onb.p", p3_rtl, p3_syn);
      check(4, "ond.p", p4_rtl, p4_syn);
    end
    $display("RESULT: %0d mismatches in 3001 vectors: ona %0d, two %0d, onb %0d, ond %0d",
             bad, bad_design[1], bad_design[2], bad_design[3], bad_design[4]);
    $finish_and_return(bad == 0 ? 0 : 1);
  end
endmodule
