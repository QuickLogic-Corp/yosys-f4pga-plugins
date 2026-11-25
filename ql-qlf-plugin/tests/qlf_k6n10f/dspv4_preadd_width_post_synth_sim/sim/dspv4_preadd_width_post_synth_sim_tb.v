// Runs each RTL design beside its synthesised netlist on the same inputs and
// compares the products: all ones first, then random values.
`timescale 1ns/1ps

module tb;
  reg [25:0] d26;
  reg [ 7:0] b8, d8, a8;
  reg [15:0] a16, d0, a0, d1, a1;
  reg [19:0] b20;
  integer i;
  integer bad;

  wire [39:0] ones32_rtl, ones32_syn, onesa_rtl, onesa_syn;
  dspv4_preadd_width_ones32     u_ones32_rtl (.d(d26), .b(b8), .p(ones32_rtl));
  dspv4_preadd_width_ones32_syn u_ones32_syn (.d(d26), .b(b8), .p(ones32_syn));
  dspv4_preadd_width_onesa      u_onesa_rtl  (.d(d26), .b(b8), .p(onesa_rtl));
  dspv4_preadd_width_onesa_syn  u_onesa_syn  (.d(d26), .b(b8), .p(onesa_syn));

  wire [42:0] ones28_rtl, ones28_syn;
  wire [33:0] ones18_rtl, ones18_syn;
  dspv4_preadd_width_ones28     u_ones28_rtl (.a(a16), .p(ones28_rtl));
  dspv4_preadd_width_ones28_syn u_ones28_syn (.a(a16), .p(ones28_syn));
  dspv4_preadd_width_ones18     u_ones18_rtl (.a(a16), .p(ones18_rtl));
  dspv4_preadd_width_ones18_syn u_ones18_syn (.a(a16), .p(ones18_syn));

  wire [37:0] ones18b_rtl, ones18b_syn, onesb_rtl, onesb_syn, copies_rtl, copies_syn;
  wire [35:0] onestrunc_rtl, onestrunc_syn;
  dspv4_preadd_width_ones18b       u_ones18b_rtl   (.d(d8), .b(b20), .p(ones18b_rtl));
  dspv4_preadd_width_ones18b_syn   u_ones18b_syn   (.d(d8), .b(b20), .p(ones18b_syn));
  dspv4_preadd_width_onesb         u_onesb_rtl     (.d(d8), .b(b20), .p(onesb_rtl));
  dspv4_preadd_width_onesb_syn     u_onesb_syn     (.d(d8), .b(b20), .p(onesb_syn));
  dspv4_preadd_width_onestrunc     u_onestrunc_rtl (.d(d8), .b(b20), .p(onestrunc_rtl));
  dspv4_preadd_width_onestrunc_syn u_onestrunc_syn (.d(d8), .b(b20), .p(onestrunc_syn));
  dspv4_preadd_width_copies        u_copies_rtl    (.d(d8), .a(a8), .b(b20), .p(copies_rtl));
  dspv4_preadd_width_copies_syn    u_copies_syn    (.d(d8), .a(a8), .b(b20), .p(copies_syn));

  wire [18:0] unsdiff_rtl, unsdiff_syn;
  dspv4_preadd_width_unsdiff     u_unsdiff_rtl (.a(a8), .b(b20), .p(unsdiff_rtl));
  dspv4_preadd_width_unsdiff_syn u_unsdiff_syn (.a(a8), .b(b20), .p(unsdiff_syn));

  wire [17:0] diffb_rtl, diffb_syn;
  wire [31:0] diffa_rtl, diffa_syn;
  dspv4_preadd_width_diffb     u_diffb_rtl (.a(a8), .b(b20), .p(diffb_rtl));
  dspv4_preadd_width_diffb_syn u_diffb_syn (.a(a8), .b(b20), .p(diffb_syn));
  dspv4_preadd_width_diffa     u_diffa_rtl (.d(d26), .b(b8), .p(diffa_rtl));
  dspv4_preadd_width_diffa_syn u_diffa_syn (.d(d26), .b(b8), .p(diffa_syn));

  wire [16:0] tie_rtl, tie_syn;
  dspv4_preadd_width_tie     u_tie_rtl (.d0(d0), .a0(a0), .d1(d1), .a1(a1), .p(tie_rtl));
  dspv4_preadd_width_tie_syn u_tie_syn (.d0(d0), .a0(a0), .d1(d1), .a1(a1), .p(tie_syn));

  task check(input [255:0] name, input [42:0] rtl, input [42:0] syn);
    if (rtl !== syn) begin
      bad = bad + 1;
      if (bad <= 10) $display("MISMATCH vector %0d %0s: rtl=%0d syn=%0d", i, name, rtl, syn);
    end
  endtask

  task compare_all;
    begin
      #1;
      check("ones32", ones32_rtl, ones32_syn);
      check("onesa", onesa_rtl, onesa_syn);
      check("ones28", ones28_rtl, ones28_syn);
      check("ones18", ones18_rtl, ones18_syn);
      check("ones18b", ones18b_rtl, ones18b_syn);
      check("onesb", onesb_rtl, onesb_syn);
      check("onestrunc", onestrunc_rtl, onestrunc_syn);
      check("copies", copies_rtl, copies_syn);
      check("unsdiff", unsdiff_rtl, unsdiff_syn);
      check("tie", tie_rtl, tie_syn);
      check("diffb", diffb_rtl, diffb_syn);
      check("diffa", diffa_rtl, diffa_syn);
    end
  endtask

  initial begin
    bad = 0;
    i = -1;
    {d26, b8, d8, a8, a16, d0, a0, d1, a1, b20} = ~150'b0;
    compare_all;
    for (i = 0; i < 3000; i = i + 1) begin
      d26 = $urandom;
      b8  = $urandom;
      d8  = $urandom;
      a8  = $urandom;
      a16 = $urandom;
      d0  = $urandom;
      a0  = $urandom;
      d1  = $urandom;
      a1  = $urandom;
      b20 = $urandom;
      compare_all;
    end
    $display("RESULT %0d mismatches in 3001 vectors", bad);
    $finish;
  end
endmodule
