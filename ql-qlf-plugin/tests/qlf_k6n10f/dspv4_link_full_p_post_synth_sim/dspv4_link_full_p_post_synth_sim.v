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

// MULT_SUB_C and MULT_RSUB_C as sources: a difference of two products fits 36 bits, a sum does not.
module dspv4_link_sub (input signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3, a4, b4,
                       output signed [37:0] p, output signed [37:0] q);
  wire signed [35:0] m1 = a0 * b0;
  wire signed [35:0] s = m1 - a1 * b1;
  assign p = s + a2 * b2;
  wire signed [35:0] m3 = a3 * b3;
  wire signed [35:0] r = a1 * b1 - m3;
  assign q = r + a4 * b4;
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

// PREADD_A_SUB_B: (d - a) * b fits 36 bits; (d + a) * b does not.
module dspv4_link_preadd_a_sub (input signed [17:0] d0, a0, b0, a1, b1,
                                output signed [35:0] t, output signed [36:0] p);
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

// PREADD_B_SUB_A: (d - b) * a fits 46 bits; (d + b) * a does not.
module dspv4_link_preadd_b_sub (input signed [15:0] d0, b0, input signed [29:0] a0,
                                input signed [17:0] a1, b1,
                                output signed [45:0] t, output signed [46:0] p);
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

// PREADD_A_SUB_B into PREADD_A_SUB_B_C, one bit narrower than the add chain.
module dspv4_link_preadd_a_sub_chain (input signed [15:0] z0, z7, z1, z6, k0, k1,
                                      input signed [17:0] a2, b2,
                                      output signed [36:0] p);
  wire signed [16:0] s0 = z0 - z7;
  wire signed [16:0] s1 = z1 - z6;
  wire signed [31:0] q1 = s1 * k1;
  wire signed [32:0] q0 = q1 + s0 * k0;
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

// PREADD_B_SUB_A into PREADD_B_SUB_A_C, one bit narrower than the add chain.
module dspv4_link_preadd_b_sub_chain (input signed [15:0] d0, b0, d1, b1,
                                      input signed [29:0] a0, a1,
                                      input signed [17:0] a2, b2,
                                      output signed [47:0] p);
  wire signed [45:0] q1 = (d1 - b1) * a1;
  wire signed [46:0] q0 = q1 + (d0 - b0) * a0;
  assign p = q0 + a2 * b2;
endmodule

// XPATH_A: (d + a) * a, with a on the 32-bit port.
module dspv4_link_xpath_a (input signed [15:0] a0, d0, input signed [17:0] a1, b1,
                           output signed [32:0] t, output signed [33:0] p);
  assign t = (d0 + a0) * a0;
  assign p = t + a1 * b1;
endmodule

// XPATH_B: (d + a) * a, with the sum on the 32-bit port.
module dspv4_link_xpath_b (input signed [17:0] a0, d0, a1, b1,
                           output signed [36:0] t, output signed [37:0] p);
  assign t = (a0 + d0) * a0;
  assign p = t + a1 * b1;
endmodule

// x * 65537 reaches 2^32 - 1: exactly the top of 33 signed bits.
module dspv4_link_top_edge (input [15:0] x, input signed [17:0] a1, b1,
                            output signed [32:0] t, output signed [33:0] p);
  assign t = $signed({1'b0, x}) * 18'sd65537;
  assign p = t + a1 * b1;
endmodule

// -x * 65537 - 1 reaches -2^32: exactly the bottom of 33 signed bits.
module dspv4_link_bottom_edge (input [15:0] x, input signed [17:0] a1, b1,
                               output signed [32:0] t, output signed [33:0] p);
  assign t = $signed({1'b0, x}) * -18'sd65537 - 33'sd1;
  assign p = t + a1 * b1;
endmodule

// One source, two consumers.
module dspv4_link_two_consumers (input signed [17:0] a0, b0, a1, b1, a2, b2,
                                 output signed [36:0] p, output signed [36:0] q);
  wire signed [35:0] t = a0 * b0;
  assign p = t + a1 * b1;
  assign q = t + a2 * b2;
endmodule

// A manually instantiated source with every parameter left at QL_DSP4.v's default (MULT).
module dspv4_link_instance (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// A constant C with no C register: the range is exactly a*b - 1.
module dspv4_link_constant_c (input signed [17:0] a0, b0, a1, b1, output signed [34:0] t, output signed [35:0] p);
  assign t = a0 * b0 - 35'sd1;
  assign p = t + a1 * b1;
endmodule

// Manually instantiated sources with constant operands and no registers. Their
// P never changes, so every link fits its 6- or 7-bit net.
module dspv4_link_unregistered (input clk, input rst, input [107:0] xy, output signed [36:0] p1, p2, p3);
  wire [49:0] add_p;
  QL_DSP4 #(.OPMODE(9'd53)) add (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_t = add_p[5:0];

  wire [49:0] pre_p;
  QL_DSP4 #(.OPMODE(9'd53), .INMODE(5'd4), .AMULTSEL(1'b1)) pre (.A(-32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'sd10), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(pre_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] pre_t = pre_p[5:0];

  wire [49:0] head_p, rsub_p;
  QL_DSP4 #(.OPMODE(9'd5)) head (.A(32'sd5), .B(18'sd8), .C(50'd0), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(head_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [6:0] head_t = head_p[6:0];

  QL_DSP4 #(.OPMODE(9'd53), .ALUMODE(2'd1)) rsub (.A(32'sd6), .B(18'sd10), .C({{43{head_t[6]}}, head_t}), .D(27'd0), .CIN(1'b1),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(rsub_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] rsub_t = rsub_p[5:0];

  assign p1 = add_t + $signed(xy[0 +: 18]) * $signed(xy[18 +: 18]);
  assign p2 = pre_t + $signed(xy[36 +: 18]) * $signed(xy[54 +: 18]);
  assign p3 = rsub_t + $signed(xy[72 +: 18]) * $signed(xy[90 +: 18]);
endmodule

// The M register clears to 0; ts is wide enough to hold c then, so the link widens.
module dspv4_link_reset (input clk, input rst, input [9:0] x, input signed [3:0] c, input signed [17:0] a1, b1,
                             output signed [36:0] p);
  reg signed [13:0] m;
  always @(posedge clk) begin
    if (rst)
      m <= 0;
    else
      m <= ($signed({1'b0, x}) + 12'sd16) * 3'sd3;
  end
  wire signed [13:0] ts = m + c;
  assign p = ts + a1 * b1;
endmodule
