// A hierarchical netlist as Synplify writes it: LUTn and dffre primitives in user modules.

module leaf (input clk, input a, input b, output q);
  wire n, vcc;
  VCC tie_vcc (.P(vcc));
  LUT2 #(.INIT(4'h8)) l_and (.O(n), .I0(a), .I1(b));
  dffre r_q (.Q(q), .D(n), .C(clk), .E(vcc), .R(vcc));
endmodule

module top (input clk, input a, input b, input c, output y);
  wire q0, q1;
  leaf u_a (.clk(clk), .a(a), .b(b), .q(q0));
  leaf u_b (.clk(clk), .a(b), .b(c), .q(q1));
  LUT2 #(.INIT(4'h6)) l_xor (.O(y), .I0(q0), .I1(q1));
endmodule
