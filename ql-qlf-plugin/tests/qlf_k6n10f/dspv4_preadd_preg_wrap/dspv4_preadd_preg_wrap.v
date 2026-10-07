// The pre-adder's OUTPUT register -- the DSP's P bank -- in a design with
// several multiplies.
//
// One instance of each register configuration, each on its own inputs, so no
// two of them are the same expression. The regin+regout one is the test: on its
// own it absorbs its output register, and inside this wrap it used to leave 33
// flops in fabric. wreduce narrows the multiply to 33 bits but visits cells in
// netlist order, so here it reached that instance's 34-bit output flop first
// and left it reading the product sign-extended -- a width the output-register
// match did not accept.
//
// Four separate QL_DSP4 cells, each with its own P register, so the two that
// register their result are not competing for one bank.

module dspv4_preadd_preg_noreg (input signed [15:0] a, b, c,
                                output signed [33:0] p);
  wire signed [16:0] preadd = b + c;
  assign p = a * preadd;
endmodule

module dspv4_preadd_preg_regin (input clk, input signed [15:0] a, b, c,
                                output signed [33:0] p);
  reg signed [15:0] a_reg, b_reg, c_reg;
  always @(posedge clk) begin
    a_reg <= a;
    b_reg <= b;
    c_reg <= c;
  end
  wire signed [16:0] preadd = b_reg + c_reg;
  assign p = a_reg * preadd;
endmodule

module dspv4_preadd_preg_regout (input clk, input signed [15:0] a, b, c,
                                 output reg signed [33:0] p);
  wire signed [16:0] preadd = b + c;
  always @(posedge clk) p <= a * preadd;
endmodule

module dspv4_preadd_preg_riro (input clk, input signed [15:0] a, b, c,
                               output reg signed [33:0] p);
  reg signed [15:0] a_reg, b_reg, c_reg;
  always @(posedge clk) begin
    a_reg <= a;
    b_reg <= b;
    c_reg <= c;
  end
  wire signed [16:0] preadd = b_reg + c_reg;
  always @(posedge clk) p <= a_reg * preadd;
endmodule

module dspv4_preadd_preg_wrap (input clk,
                               input signed [15:0] a_noreg, b_noreg, c_noreg,
                               input signed [15:0] a_regin, b_regin, c_regin,
                               input signed [15:0] a_regout, b_regout, c_regout,
                               input signed [15:0] a_riro, b_riro, c_riro,
                               output signed [33:0] p_noreg, p_regin,
                               output signed [33:0] p_regout, p_riro);
  dspv4_preadd_preg_noreg  u_noreg  (.a(a_noreg),  .b(b_noreg),  .c(c_noreg),  .p(p_noreg));
  dspv4_preadd_preg_regin  u_regin  (.clk(clk), .a(a_regin),  .b(b_regin),  .c(c_regin),  .p(p_regin));
  dspv4_preadd_preg_regout u_regout (.clk(clk), .a(a_regout), .b(b_regout), .c(c_regout), .p(p_regout));
  dspv4_preadd_preg_riro   u_riro   (.clk(clk), .a(a_riro),   .b(b_riro),   .c(c_riro),   .p(p_riro));
endmodule
