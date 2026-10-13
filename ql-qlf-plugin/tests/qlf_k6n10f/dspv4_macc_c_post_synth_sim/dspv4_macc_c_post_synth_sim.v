// RTL-against-netlist simulation for the shapes in dspv4_macc_c,
// dspv4_macc_c_reader, dspv4_macc_c_self and dspv4_mult_regin_port.
//
// The structural tests pin what the netlist contains; this one pins what it
// computes. The bug these shapes cover leaves a module output with no driver,
// which `check -assert` passes and a cell count can only infer -- but a
// netlist simulated against the RTL it came from shows `x` on every cycle.
// Each module here is a copy of its structural test's design.
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
