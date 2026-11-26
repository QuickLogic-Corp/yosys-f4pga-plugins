// The check pass counts enable nets on every QL_DSP4: the pass's own cells, the
// Synplify bridge's, macros and hand-written ones. A tied-high enable on a used
// register is a net. Hand-written cells, one for each side:
//
//   warns   A, B and C on their own enables and a P register with CEP tied
//           high: four nets, so ql_dsp4_check must warn
//   fits    A and B on their own enables and a P register with CEP tied high:
//           three nets, so it must not
module dspv4_check_warns (input clk, input ea, input eb, input ec,
                          input [15:0] a, input [15:0] b, input [31:0] c, output [63:0] p);
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .AREG0(1'b1), .BREG0(1'b1), .CREG(1'b1), .PREG(1'b1)) u (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .C({18'b0, c}), .CIN(1'b0),
    .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(ea), .CEB(eb), .CEC(ec), .CED(1'b1), .CEP(1'b1), .P(p));
endmodule

module dspv4_check_fits (input clk, input ea, input eb,
                         input [15:0] a, input [15:0] b, output [63:0] p);
  QL_DSP4 #(.OPMODE(9'b00_000_01_01), .AREG0(1'b1), .BREG0(1'b1), .PREG(1'b1)) u (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .C(50'b0), .CIN(1'b0),
    .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(ea), .CEB(eb), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p));
endmodule

module dspv4_enable_tied_high_check (input clk, input ea, input eb, input ec,
                                     input [15:0] a, input [15:0] b, input [31:0] c,
                                     output [63:0] p_warns, output [63:0] p_fits);
  dspv4_check_warns u_warns (.clk(clk), .ea(ea), .eb(eb), .ec(ec), .a(a), .b(b), .c(c), .p(p_warns));
  dspv4_check_fits  u_fits  (.clk(clk), .ea(ea), .eb(eb), .a(a), .b(b), .p(p_fits));
endmodule
