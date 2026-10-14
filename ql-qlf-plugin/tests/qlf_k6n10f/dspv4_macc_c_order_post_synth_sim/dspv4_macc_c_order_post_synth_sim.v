// The three-input accumulator written both ways round.
//
// `(a * b + p) + c` closes the feedback on the inner adder and `p + (a * b + c)`
// on the outer one. Both are the A*B + P + C that MULT_ACC_C computes in one
// cell, but the pass only looked for the feedback on the inner adder, so the
// second spelling fell back to MULT_ADD_C with the outer add left in fabric:
// 50 carry cells for the same arithmetic. The .tcl pins the mode by name for
// each; sim/ runs every netlist against this RTL.
//
// The two subtract spellings have no control word with a C term, so they stay
// MULT_SUB_C / MULT_RSUB_C with the outer add in fabric. They are here to pin
// that the refusal still lands on the same cell and the same answer.

module dspv4_macc_c_inner (input clk, input rst,
                           input signed [17:0] a, input signed [17:0] b,
                           input signed [33:0] c,
                           output reg signed [49:0] p);
  always @(posedge clk)
    if (rst) p <= 0; else p <= (a * b + p) + c;
endmodule

module dspv4_macc_c_outer (input clk, input rst,
                           input signed [17:0] a, input signed [17:0] b,
                           input signed [33:0] c,
                           output reg signed [49:0] p);
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + (a * b + c);
endmodule

module dspv4_macc_c_outer_sub (input clk, input rst,
                               input signed [17:0] a, input signed [17:0] b,
                               input signed [33:0] c,
                               output reg signed [49:0] p);
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + (c - a * b);
endmodule

module dspv4_macc_c_outer_rsub (input clk, input rst,
                                input signed [17:0] a, input signed [17:0] b,
                                input signed [33:0] c,
                                output reg signed [49:0] p);
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + (a * b - c);
endmodule
