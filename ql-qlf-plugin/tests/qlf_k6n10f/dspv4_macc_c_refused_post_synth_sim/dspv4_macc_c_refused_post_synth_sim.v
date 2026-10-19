// Three-input accumulator shapes the MULT_ACC_C fold must refuse. Each one
// keeps the multiply in a DSP and leaves the outer add in fabric with p's
// register; sim/ runs every netlist against this RTL.
//
// The subtract spellings have no accumulating control word with a C term, so
// the inner subtract folds alone as MULT_SUB_C / MULT_RSUB_C.
//
// The narrow spellings keep the first sum in fewer bits than its operands
// make. The RTL wraps there and then sign-extends; the DSP would add the full
// sum. C is 36 bits so that a*b + c really does overflow 36 bits.

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

module dspv4_macc_c_narrow_outer (input clk, input rst,
                                  input signed [17:0] a, input signed [17:0] b,
                                  input signed [35:0] c,
                                  output reg signed [49:0] p);
  wire signed [35:0] t = a * b + c;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + t;
endmodule

module dspv4_macc_c_narrow_inner (input clk, input rst,
                                  input signed [17:0] a, input signed [17:0] b,
                                  input signed [35:0] c,
                                  output reg signed [49:0] p);
  wire signed [35:0] s = a * b + p;
  always @(posedge clk)
    if (rst) p <= 0; else p <= s + c;
endmodule
