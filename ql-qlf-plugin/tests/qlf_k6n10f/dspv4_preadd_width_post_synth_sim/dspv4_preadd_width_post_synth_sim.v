// Every product right at the pre-adder's width limits, for unsigned operands
// whose top bits are ones. Which mode each shape takes is checked by the test
// named beside it; this test checks the values.
//
//   refused, dspv4_preadd_refused:  ones32 ones18b onestrunc copies unsdiff
//   folded, dspv4_preadd_widths:    onesa onesb
//   folded, dspv4_xpath:            ones28 ones18
//   folded, dspv4_preadd_both:      tie
//   folded, dspv4_preadd_sub_unsigned: diffb diffa

module dspv4_preadd_width_ones32 (input [25:0] d, input [7:0] b, output [39:0] p);
  assign p = (d + 31'h7FFFFFFF) * b;
endmodule

module dspv4_preadd_width_onesa (input [25:0] d, input [7:0] b, output [39:0] p);
  assign p = (d + 30'h3FFFFFFF) * b;
endmodule

module dspv4_preadd_width_ones28 (input [15:0] a, output [42:0] p);
  assign p = (26'h3FFFFFF + a) * a;
endmodule

module dspv4_preadd_width_ones18 (input [15:0] a, output [33:0] p);
  assign p = (a + 16'hFFFF) * a;
endmodule

module dspv4_preadd_width_ones18b (input [7:0] d, input [19:0] b, output [37:0] p);
  assign p = (d + 17'h1FFFF) * b;
endmodule

module dspv4_preadd_width_onesb (input [7:0] d, input [19:0] b, output [37:0] p);
  assign p = (d + 16'hFFFF) * b;
endmodule

module dspv4_preadd_width_onestrunc (input [7:0] d, input [19:0] b, output [35:0] p);
  wire [15:0] s = d + 16'hFFFF;
  assign p = s * b;
endmodule

module dspv4_preadd_width_copies (input [7:0] d, input [7:0] a, input [19:0] b, output [37:0] p);
  wire [17:0] s = d + {{9{a[7]}}, a};
  assign p = s * b;
endmodule

module dspv4_preadd_width_unsdiff (input [7:0] a, input [19:0] b, output [18:0] p);
  wire [18:0] s = 18'h3FFFF - a;
  assign p = s * b;
endmodule

module dspv4_preadd_width_tie (input [15:0] d0, input [15:0] a0,
                               input [15:0] d1, input [15:0] a1, output [16:0] p);
  wire [16:0] s0 = d0 - a0;
  wire [16:0] s1 = d1 + a1;
  assign p = s0 * s1;
endmodule

module dspv4_preadd_width_diffb (input [7:0] a, input [19:0] b, output [17:0] p);
  wire [17:0] s = 17'h1FFFF - a;
  assign p = s * b;
endmodule

module dspv4_preadd_width_diffa (input [25:0] d, input [7:0] b, output [31:0] p);
  wire [31:0] s = d - 31'h7FFFFFFF;
  assign p = s * b;
endmodule
