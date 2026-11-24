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

// An accumulator as the source; P keeps adding above bit 35. Instantiated manually:
// whether inference folds this as MULT_ACC depends on the Yosys version.
module dspv4_link_kept_acc (input clk, input rst, input signed [17:0] a0, b0, a1, b1,
                            output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 #(.OPMODE(9'd37), .PREG(1'b1)) u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
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

// Unsigned: a0 * b0 + c can need 35 bits but keeps 34. Only the top is outside the net.
module dspv4_link_kept_unsigned_wrap (input [16:0] a0, b0, a1, b1, input [33:0] c,
                                      output [33:0] t, output [35:0] p);
  assign t = a0 * b0 + c;
  assign p = t + a1 * b1;
endmodule

// Unsigned: x * 65537 + 1 reaches 2^32, one past the top of 32 bits.
module dspv4_link_kept_unsigned_top_edge (input [15:0] x, input [16:0] a1, b1,
                                          output [31:0] t, output [34:0] p);
  assign t = x * 17'd65537 + 32'd1;
  assign p = t + a1 * b1;
endmodule

// A 32 x 18 product minus a 49-bit c reaches 2^49: past the 50-bit P port.
module dspv4_link_kept_exceed (input signed [31:0] a0, input signed [17:0] b0, input signed [48:0] c0,
                               input signed [17:0] a1, b1, output signed [48:0] t, output signed [49:0] p);
  assign t = a0 * b0 - c0;
  assign p = t + a1 * b1;
endmodule

// A manually instantiated source that rounds and shifts P.
module dspv4_link_kept_rss (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 #(.USE_RSS(1'b1)) u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// A manually instantiated source that reads ACIN. The techmap leaves it unlowered.
module dspv4_link_kept_acin (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 #(.A_IN_SEL(1'b1)) u (.A(32'd0), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN({{14{a0[17]}}, a0}), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// A manually instantiated source with a carry-in its mode does not need.
module dspv4_link_kept_carry (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0), .CIN(1'b1),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// The sources of dspv4_link_unregistered, each with one register on. That
// register's reset value is what takes each link out of its 6-bit net.
// head -> rsub still widens: head's range [0, 40] fits 7 bits.
module dspv4_link_kept_register_zeros (input clk, input rst, input [251:0] xy, output signed [36:0] p1, p2, p3, p4, p5, p6, p7);
  wire [49:0] add_areg1_p;
  QL_DSP4 #(.OPMODE(9'd53), .AREG1(1'b1)) add_areg1 (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_areg1_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_areg1_t = add_areg1_p[5:0];

  wire [49:0] add_breg1_p;
  QL_DSP4 #(.OPMODE(9'd53), .BREG1(1'b1)) add_breg1 (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_breg1_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_breg1_t = add_breg1_p[5:0];

  wire [49:0] add_creg_p;
  QL_DSP4 #(.OPMODE(9'd53), .CREG(1'b1)) add_creg (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_creg_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_creg_t = add_creg_p[5:0];

  wire [49:0] add_mreg_p;
  QL_DSP4 #(.OPMODE(9'd53), .MREG(1'b1)) add_mreg (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_mreg_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_mreg_t = add_mreg_p[5:0];

  wire [49:0] pre_dreg_p;
  QL_DSP4 #(.OPMODE(9'd53), .INMODE(5'd4), .AMULTSEL(1'b1), .DREG(1'b1)) pre_dreg (.A(-32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'sd10), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(pre_dreg_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] pre_dreg_t = pre_dreg_p[5:0];

  wire [49:0] pre_adreg_p;
  QL_DSP4 #(.OPMODE(9'd53), .INMODE(5'd4), .AMULTSEL(1'b1), .ADREG(1'b1)) pre_adreg (.A(-32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'sd10), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(pre_adreg_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] pre_adreg_t = pre_adreg_p[5:0];

  wire [49:0] head_p, rsub_p;
  QL_DSP4 #(.OPMODE(9'd5), .PREG(1'b1)) head (.A(32'sd5), .B(18'sd8), .C(50'd0), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(head_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [6:0] head_t = head_p[6:0];

  QL_DSP4 #(.OPMODE(9'd53), .ALUMODE(2'd1)) rsub (.A(32'sd6), .B(18'sd10), .C({{43{head_t[6]}}, head_t}), .D(27'd0), .CIN(1'b1),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(rsub_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] rsub_t = rsub_p[5:0];

  assign p1 = add_areg1_t + $signed(xy[0 +: 18]) * $signed(xy[18 +: 18]);
  assign p2 = add_breg1_t + $signed(xy[36 +: 18]) * $signed(xy[54 +: 18]);
  assign p3 = add_creg_t + $signed(xy[72 +: 18]) * $signed(xy[90 +: 18]);
  assign p4 = add_mreg_t + $signed(xy[108 +: 18]) * $signed(xy[126 +: 18]);
  assign p5 = pre_dreg_t + $signed(xy[144 +: 18]) * $signed(xy[162 +: 18]);
  assign p6 = pre_adreg_t + $signed(xy[180 +: 18]) * $signed(xy[198 +: 18]);
  assign p7 = rsub_t + $signed(xy[216 +: 18]) * $signed(xy[234 +: 18]);
endmodule

// One bit short on the paths where AD drives the 18-bit port or B is the multiplier.
module dspv4_link_kept_preadd_b_short (input signed [15:0] d0, b0, input signed [29:0] a0, input signed [17:0] a1, b1,
                                       output signed [45:0] t, output signed [46:0] p);
  assign t = (d0 + b0) * a0;
  assign p = t + a1 * b1;
endmodule

module dspv4_link_kept_xpath_a_short (input signed [15:0] a0, d0, input signed [17:0] a1, b1,
                                      output signed [31:0] t, output signed [32:0] p);
  assign t = (d0 + a0) * a0;
  assign p = t + a1 * b1;
endmodule

module dspv4_link_kept_xpath_b_short (input signed [17:0] a0, d0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  assign t = (a0 + d0) * a0;
  assign p = t + a1 * b1;
endmodule

// C mixes t's bits in place with other bits: not a link, but its bits can end up on two inputs.
module dspv4_link_kept_mixed (input signed [17:0] a0, b0, a1, b1, input signed [5:0] x,
                              output signed [35:0] t, output signed [36:0] p);
  assign t = a0 * b0;
  assign p = $signed({x, t[29:0]}) + a1 * b1;
endmodule

module dspv4_link_kept_mixed_shift (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  assign t = a0 * b0;
  assign p = $signed({t[35:4], 4'b0}) + a1 * b1;
endmodule

// A manually instantiated source that reads BCIN. The techmap leaves it unlowered.
module dspv4_link_kept_bcin (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 #(.B_IN_SEL(1'b1)) u (.A({{14{a0[17]}}, a0}), .B(18'd0), .C(50'd0), .D(27'd0), .CIN(1'b0),
             .ACIN(32'd0), .BCIN(b0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// A manually instantiated source with no CIN connection.
module dspv4_link_kept_no_cin (input signed [17:0] a0, b0, a1, b1, output signed [35:0] t, output signed [36:0] p);
  wire [49:0] p0;
  QL_DSP4 u (.A({{14{a0[17]}}, a0}), .B(b0), .C(50'd0), .D(27'd0),
             .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(p0),
             .CLK(1'b0), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
             .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1));
  assign t = p0[35:0];
  assign p = t + a1 * b1;
endmodule

// Only the first register stage on A, then only on B. Each still clears to 0 at reset.
module dspv4_link_kept_first_stage_registers (input clk, input rst, input [71:0] xy, output signed [36:0] p1, p2);
  wire [49:0] add_areg0_p;
  QL_DSP4 #(.OPMODE(9'd53), .AREG0(1'b1)) add_areg0 (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_areg0_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_areg0_t = add_areg0_p[5:0];

  wire [49:0] add_breg0_p;
  QL_DSP4 #(.OPMODE(9'd53), .BREG0(1'b1)) add_breg0 (.A(32'sd5), .B(18'sd7), .C(-50'sd40), .D(27'd0), .CIN(1'b0),
      .ACIN(32'd0), .BCIN(18'd0), .PCIN(50'd0), .CCIN(1'b0), .SIGNCIN(1'b0), .P(add_breg0_p),
      .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
      .ARSTN(1'b1), .RSTN(!rst), .ACCRSTN(!rst));

  wire signed [5:0] add_breg0_t = add_breg0_p[5:0];

  assign p1 = add_areg0_t + $signed(xy[0 +: 18]) * $signed(xy[18 +: 18]);
  assign p2 = add_breg0_t + $signed(xy[36 +: 18]) * $signed(xy[54 +: 18]);
endmodule
