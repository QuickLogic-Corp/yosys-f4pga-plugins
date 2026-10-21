// Cells the DSP cannot take, each for a different reason. Every shape leaves
// something in fabric, and the pass's summary must name it with the true
// reason -- counted only if the cell really stayed out.
//
//   k2s  two output registers; the first is marked keep
//   mk   M register marked keep; the adder reads it
//   mz   M register resets to 5
//   mc   M register on clk2, result register on clk: the cell keeps M
//   mp   M register holds the product with another bit above it
//   ap   the adder reads the product padded with a zero, not its sign
//   fk   accumulate plus C, the first sum marked keep
//   rk   the product register's input is marked keep
//   ck   the adder cell itself is marked keep (set by the .tcl)
//   pd   c - (d + a) * b: no pre-adder word for a subtract from C
module k2s (input clk, input signed [15:0] a, b, output signed [31:0] p);
  (* keep *) reg signed [31:0] k1;
  reg signed [31:0] k2;
  always @(posedge clk) begin
    k1 <= a * b;
    k2 <= k1;
  end
  assign p = k2;
endmodule

module mk (input clk, input signed [15:0] a, b, input signed [33:0] c, output signed [34:0] p);
  (* keep *) reg signed [31:0] m;
  always @(posedge clk) m <= a * b;
  assign p = m + c;
endmodule

module mz (input clk, rstn, input signed [15:0] a, b, input signed [33:0] c, output signed [34:0] p);
  reg signed [31:0] m;
  always @(posedge clk)
    if (!rstn) m <= 5;
    else       m <= a * b;
  assign p = m + c;
endmodule

module mc (input clk, clk2, input signed [15:0] a, b, input signed [33:0] c, output reg signed [34:0] p);
  reg signed [31:0] m;
  always @(posedge clk2) m <= a * b;
  always @(posedge clk) p <= m + c;
endmodule

module mp (input clk, x, input signed [15:0] a, b, input signed [33:0] c, output signed [34:0] p);
  wire signed [31:0] prod = a * b;
  reg signed [32:0] m;
  always @(posedge clk) m <= {x, prod};
  assign p = $signed(m) + c;
endmodule

module ap (input signed [15:0] a, b, input signed [33:0] c, output signed [34:0] p);
  wire signed [31:0] prod = a * b;
  assign p = $signed({1'b0, prod}) + c;
endmodule

module fk (input clk, rst, input signed [15:0] a, b, input signed [33:0] c, output reg signed [49:0] p);
  (* keep *) wire signed [49:0] s1 = a * b + p;
  always @(posedge clk)
    if (rst) p <= 0;
    else     p <= s1 + c;
endmodule

module rk (input clk, input signed [15:0] a, b, output reg signed [31:0] p);
  (* keep *) wire signed [31:0] prod = a * b;
  always @(posedge clk) p <= prod;
endmodule

module ck (input signed [15:0] a, b, input signed [33:0] c, output signed [34:0] p);
  assign p = a * b + c;
endmodule

module pd (input signed [15:0] d, a, b, input signed [33:0] c, output signed [34:0] p);
  assign p = c - (d + a) * b;
endmodule
