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
