// C links whose source's P can hold a value the RTL net does not: they must stay.

// t keeps 30 bits of a 36-bit product.
module dspv4_link_kept_trunc (input signed [17:0] a0, b0, a1, b1,
                              output signed [29:0] t, output signed [36:0] p);
  assign t = a0 * b0;
  assign p = t + a1 * b1;
endmodule

// s1 can need 37 bits but keeps 36, so it wraps.
module dspv4_link_kept_wrap (input signed [17:0] a0, b0, a1, b1, input signed [35:0] c,
                             output signed [36:0] p);
  wire signed [35:0] s1 = a0 * b0 + c;
  assign p = a1 * b1 + s1;
endmodule

// A signed product read as unsigned: zero-extended, but it can be negative.
module dspv4_link_kept_zext (input signed [17:0] a0, b0, a1, b1,
                             output signed [36:0] p);
  wire signed [35:0] t = a0 * b0;
  assign p = $signed({1'b0, t}) + a1 * b1;
endmodule

// An accumulator as the source. The DSP keeps adding above bit 35.
module dspv4_link_kept_acc (input clk, input rst, input signed [17:0] a0, b0, a1, b1,
                            output signed [36:0] p);
  reg signed [35:0] acc;
  always @(posedge clk) begin
    if (rst)
      acc <= 0;
    else
      acc <= acc + a0 * b0;
  end
  assign p = acc + a1 * b1;
endmodule

// (d + a) is 19 bits, so the product can need 37 bits; t has 36.
module dspv4_link_kept_preadd (input signed [17:0] d0, a0, b0, a1, b1,
                               output signed [35:0] t, output signed [36:0] p);
  assign t = (d0 + a0) * b0;
  assign p = t + a1 * b1;
endmodule

// The M register clears to 0 while the product never is 0, so tu = c < 0 during reset.
module dspv4_link_kept_reset (input clk, input rst, input [9:0] x, input signed [3:0] c,
                              input [16:0] a1, b1, output [36:0] p);
  reg signed [13:0] m;
  always @(posedge clk) begin
    if (rst)
      m <= 0;
    else
      m <= ($signed({1'b0, x}) + 12'sd16) * 3'sd3;
  end
  wire [13:0] tu = m + c;
  assign p = tu + a1 * b1;
endmodule

// Two DSPs that feed each other: a loop of links.
module dspv4_link_kept_loop (input clk, input rst, input signed [17:0] a0, b0, a1, b1,
                             output signed [39:0] y, output signed [39:0] z);
  reg signed [39:0] p1, p2;
  always @(posedge clk) begin
    if (rst) begin
      p1 <= 0;
      p2 <= 0;
    end else begin
      p1 <= a0 * b0 + p2;
      p2 <= a1 * b1 + p1;
    end
  end
  assign y = p1;
  assign z = p2;
endmodule

// x * 65537 + 1 reaches 2^32: one past the top of 33 signed bits.
module dspv4_link_kept_top_edge (input [15:0] x, input signed [17:0] a1, b1,
                                 output signed [32:0] t, output signed [33:0] p);
  assign t = $signed({1'b0, x}) * 18'sd65537 + 33'sd1;
  assign p = t + a1 * b1;
endmodule

// -x * 65537 - 2 reaches -2^32 - 1: one past the bottom of 33 signed bits.
module dspv4_link_kept_bottom_edge (input [15:0] x, input signed [17:0] a1, b1,
                                    output signed [32:0] t, output signed [33:0] p);
  assign t = $signed({1'b0, x}) * -18'sd65537 - 33'sd2;
  assign p = t + a1 * b1;
endmodule

// A 32 x 18 product minus a 49-bit c reaches 2^49: past the 50-bit P port.
module dspv4_link_kept_exceed (input signed [31:0] a0, input signed [17:0] b0, input signed [48:0] c0,
                               input signed [17:0] a1, b1, output signed [48:0] t, output signed [49:0] p);
  assign t = a0 * b0 - c0;
  assign p = t + a1 * b1;
endmodule

// A hand instance that rounds and shifts P.
module dspv4_link_kept_rss (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 #(.USE_RSS(1'b1)) u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// A hand instance that reads ACIN. The techmap leaves it unlowered.
module dspv4_link_kept_acin (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 #(.A_IN_SEL(1'b1)) u (.A(32'd0), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN({{14{a0[17]}}, a0}), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// A hand instance with a carry-in its mode does not tie.
module dspv4_link_kept_carry (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b1),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule
