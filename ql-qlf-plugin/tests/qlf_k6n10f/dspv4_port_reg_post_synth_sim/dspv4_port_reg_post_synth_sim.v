// Four shapes where a register also drives a module output.
//
// dspv4_macc_c is the baseline: the three-input accumulator folds whole. The
// other three put a register on a DSP operand port while a module output
// also reads it, so the pass has to copy the register into the bank rather
// than move it. Moving it left the output with no driver -- `assign p = 50'hx`
// in the netlist, with `check -assert` reporting nothing. The .tcl pins the
// structure of each; sim/ runs every netlist against this RTL.

module dspv4_macc_c (input clk, input rst,
                     input signed [17:0] a, input signed [17:0] b,
                     input signed [33:0] c,
                     output reg signed [49:0] p);
  wire signed [49:0] s = a * b + p;
  always @(posedge clk)
    if (rst) p <= 0; else p <= s + c;
endmodule

module dspv4_macc_c_reader (input clk, input rst,
                            input signed [17:0] a, input signed [17:0] b,
                            input signed [33:0] c,
                            output reg signed [49:0] p,
                            output reg signed [49:0] q);
  wire signed [49:0] s = a * b + p;
  always @(posedge clk) begin
    if (rst) p <= 0; else p <= s + c;
    q <= s;
  end
endmodule

module dspv4_macc_c_self (input clk, input rst,
                          input signed [17:0] a, input signed [17:0] b,
                          output reg signed [49:0] p);
  wire signed [49:0] s = a * b + p;
  always @(posedge clk)
    if (rst) p <= 0; else p <= s + s;
endmodule

module dspv4_mult_regin_port (input clk,
                              input signed [17:0] a, input signed [17:0] b,
                              output signed [35:0] p,
                              output signed [17:0] q);
  reg signed [17:0] a_reg;
  always @(posedge clk) a_reg <= a;
  assign p = a_reg * b;
  assign q = a_reg;
endmodule
