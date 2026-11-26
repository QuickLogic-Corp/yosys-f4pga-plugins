// A register with no enable still has an enable pin, tied high, and a tied-high
// enable takes one of the three crossbar inputs like a signal does. ql_dspv4
// used to skip constants when it counted enables, so it built cells that need
// four.
//
//   evict  A, B and C on their own enables, and a P register with none: four
//          nets. The narrowest port, B, goes back to fabric and three remain.
//   keep   A and B on their own enables, C and P with none: the two tied-high
//          enables are one net, so three. Nothing is given up.
//   shared A, D and P on their own enables, B and C with none: four nets, since
//          the two tied-high enables are one. Giving up B, the narrowest port,
//          frees no slot because C still holds the tied-high net, so B stays
//          and D goes instead.
module dspv4_tied_evict (input clk, input ea, input eb, input ec,
                         input [15:0] a, input [15:0] b, input [31:0] c,
                         output reg [47:0] p);
  reg [15:0] ar, br;
  reg [31:0] cr;
  always @(posedge clk) if (ea) ar <= a;
  always @(posedge clk) if (eb) br <= b;
  always @(posedge clk) if (ec) cr <= c;
  always @(posedge clk) p <= ar * br + cr;
endmodule

module dspv4_tied_keep (input clk, input ea, input eb,
                        input [15:0] a, input [15:0] b, input [31:0] c,
                        output reg [47:0] p);
  reg [15:0] ar, br;
  reg [31:0] cr;
  always @(posedge clk) if (ea) ar <= a;
  always @(posedge clk) if (eb) br <= b;
  always @(posedge clk) cr <= c;
  always @(posedge clk) p <= ar * br + cr;
endmodule

module dspv4_tied_shared (input clk, input ea, input ed, input ep,
                          input [15:0] a, input [15:0] b, input [31:0] c, input [15:0] d,
                          output reg [47:0] p);
  reg [15:0] ar, br, dr;
  reg [31:0] cr;
  always @(posedge clk) if (ea) ar <= a;
  always @(posedge clk) br <= b;
  always @(posedge clk) cr <= c;
  always @(posedge clk) if (ed) dr <= d;
  always @(posedge clk) if (ep) p <= (dr + ar) * br + cr;
endmodule

// Each block has its own inputs. With shared inputs and shared enables, the
// flow merges the identical operand flops of the two blocks.
module dspv4_enable_tied_high_evicts (input clk,
                                      input ea, input eb, input ec,
                                      input [15:0] a, input [15:0] b, input [31:0] c,
                                      input ka, input kb,
                                      input [15:0] ka_d, input [15:0] kb_d, input [31:0] kc_d,
                                      input sa, input sd, input sp,
                                      input [15:0] sa_d, input [15:0] sb_d, input [31:0] sc_d, input [15:0] sd_d,
                                      output [47:0] p_evict, output [47:0] p_keep, output [47:0] p_shared);
  dspv4_tied_evict  u_evict  (.clk(clk), .ea(ea), .eb(eb), .ec(ec), .a(a), .b(b), .c(c), .p(p_evict));
  dspv4_tied_keep   u_keep   (.clk(clk), .ea(ka), .eb(kb), .a(ka_d), .b(kb_d), .c(kc_d), .p(p_keep));
  dspv4_tied_shared u_shared (.clk(clk), .ea(sa), .ed(sd), .ep(sp), .a(sa_d), .b(sb_d), .c(sc_d), .d(sd_d), .p(p_shared));
endmodule
