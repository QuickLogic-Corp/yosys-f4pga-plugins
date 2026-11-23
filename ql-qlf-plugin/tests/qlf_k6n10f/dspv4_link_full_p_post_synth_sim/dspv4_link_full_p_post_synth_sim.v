// C links whose source's value always fits the RTL net: they must be widened.

// The dsp_cascade_small shape: the head's product is also an output.
module dspv4_link_small (input signed [17:0] a0, b0, a1, b1,
                         output signed [35:0] t, output signed [36:0] p);
  assign t = a0 * b0;
  assign p = t + a1 * b1;
endmodule

// The cascade_chain shape. s3 fits 37 bits only by the range passed down from s2.
module dspv4_link_chain (input signed [17:0] a1, b1, a2, b2, a3, b3, a4, b4,
                         output signed [37:0] p);
  wire signed [35:0] s1 = a1 * b1;
  wire signed [36:0] s2 = a2 * b2 + s1;
  wire signed [36:0] s3 = a3 * b3 + s2;
  assign p = a4 * b4 + s3;
endmodule

// The same chain, statements in reverse order.
module dspv4_link_chain_reversed (input signed [17:0] a1, b1, a2, b2, a3, b3, a4, b4,
                                  output signed [37:0] p);
  assign p = a4 * b4 + s3;
  wire signed [36:0] s3 = a3 * b3 + s2;
  wire signed [36:0] s2 = a2 * b2 + s1;
  wire signed [35:0] s1 = a1 * b1;
endmodule

// Registered sums with constant coefficients, as in dsp_filter_matrix.
module dspv4_link_registered (input clk, input rst, input signed [17:0] x,
                              output signed [37:0] y);
  reg signed [49:0] s0, s1, s2;
  always @(posedge clk)
    if (rst) begin
      s0 <= 0;
      s1 <= 0;
      s2 <= 0;
    end else begin
      s2 <= x * 18'sd7777;
      s1 <= s2 + x * -18'sd14203;
      s0 <= s1 + x * 18'sd21001;
    end
  assign y = s0;
endmodule

// A link into each subtract direction.
module dspv4_link_sub (input signed [17:0] ar, ai, br, bi, cr, ci,
                       output signed [36:0] pr, output signed [36:0] pi);
  wire signed [35:0] m1 = ar * br;
  wire signed [35:0] m2 = ai * bi;
  assign pr = m1 - ai * bi;
  assign pi = cr * ci - m2;
endmodule

// Unsigned all the way: the link is zero-extended.
module dspv4_link_zero (input [16:0] a0, b0, a1, b1,
                        output [33:0] t, output [34:0] p);
  assign t = a0 * b0;
  assign p = t + a1 * b1;
endmodule

// PREADD_A_MULT_B: (d + a) * b.
module dspv4_link_preadd_a (input signed [17:0] d0, a0, b0, a1, b1,
                            output signed [36:0] t, output signed [37:0] p);
  assign t = (d0 + a0) * b0;
  assign p = t + a1 * b1;
endmodule

// PREADD_A_SUB_B: (d - a) * b.
module dspv4_link_preadd_a_sub (input signed [17:0] d0, a0, b0, a1, b1,
                                output signed [36:0] t, output signed [37:0] p);
  assign t = (d0 - a0) * b0;
  assign p = t + a1 * b1;
endmodule

// PREADD_B_MULT_A: (d + b) * a, with a too wide for the 18-bit port.
module dspv4_link_preadd_b (input signed [15:0] d0, b0, input signed [29:0] a0,
                            input signed [17:0] a1, b1,
                            output signed [46:0] t, output signed [47:0] p);
  assign t = (d0 + b0) * a0;
  assign p = t + a1 * b1;
endmodule

// PREADD_B_SUB_A: (d - b) * a.
module dspv4_link_preadd_b_sub (input signed [15:0] d0, b0, input signed [29:0] a0,
                                input signed [17:0] a1, b1,
                                output signed [46:0] t, output signed [47:0] p);
  assign t = (d0 - b0) * a0;
  assign p = t + a1 * b1;
endmodule

// PREADD_A_MULT_B into PREADD_A_MULT_B_C: dsp_filter_matrix's symmetric filter.
module dspv4_link_preadd_a_chain (input signed [15:0] z0, z7, z1, z6, k0, k1,
                                  input signed [17:0] a2, b2,
                                  output signed [36:0] p);
  wire signed [16:0] s0 = z0 + z7;
  wire signed [16:0] s1 = z1 + z6;
  wire signed [32:0] q1 = s1 * k1;
  wire signed [33:0] q0 = q1 + s0 * k0;
  assign p = q0 + a2 * b2;
endmodule

// PREADD_A_SUB_B into PREADD_A_SUB_B_C.
module dspv4_link_preadd_a_sub_chain (input signed [15:0] z0, z7, z1, z6, k0, k1,
                                      input signed [17:0] a2, b2,
                                      output signed [36:0] p);
  wire signed [16:0] s0 = z0 - z7;
  wire signed [16:0] s1 = z1 - z6;
  wire signed [32:0] q1 = s1 * k1;
  wire signed [33:0] q0 = q1 + s0 * k0;
  assign p = q0 + a2 * b2;
endmodule

// PREADD_B_MULT_A into PREADD_B_MULT_A_C.
module dspv4_link_preadd_b_chain (input signed [15:0] d0, b0, d1, b1,
                                  input signed [29:0] a0, a1,
                                  input signed [17:0] a2, b2,
                                  output signed [48:0] p);
  wire signed [46:0] q1 = (d1 + b1) * a1;
  wire signed [47:0] q0 = q1 + (d0 + b0) * a0;
  assign p = q0 + a2 * b2;
endmodule

// PREADD_B_SUB_A into PREADD_B_SUB_A_C.
module dspv4_link_preadd_b_sub_chain (input signed [15:0] d0, b0, d1, b1,
                                      input signed [29:0] a0, a1,
                                      input signed [17:0] a2, b2,
                                      output signed [48:0] p);
  wire signed [46:0] q1 = (d1 - b1) * a1;
  wire signed [47:0] q0 = q1 + (d0 - b0) * a0;
  assign p = q0 + a2 * b2;
endmodule
