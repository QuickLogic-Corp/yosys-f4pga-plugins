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
