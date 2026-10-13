// Eleven shapes of one bug: the RTL keeps fewer product bits than the operands
// make, and what happens next decides whether the DSP may take the adder.
// The first eight read the result above that cut and must be refused; the
// last three do not, and must keep folding. Counts quoted are RTL against the
// post-synthesis netlist on random vectors, before the guard.

// The RTL keeps 17 bits of a 35-bit product and then adds it at full width.
// The DSP has no truncation between its multiplier and its ALU, so fusing the
// adder adds the whole product and the dropped bits come back in the sum --
// 3000 of 3000 random vectors wrong on the unguarded pass, with `check` clean.
// The multiply still belongs in a DSP; only the addition has to stay soft.
module dspv4_trunc_add (input [16:0] a, input [17:0] b, input [34:0] c,
                        output [34:0] p);
  wire [16:0] m = a * b;
  assign p = m + c;
endmodule

// Same truncated product as dspv4_trunc_add, subtracted from C. MULT_SUB_C
// has the same ALU behind the same untruncated multiplier, and was wrong on
// 3000 of 3000 vectors.
module dspv4_trunc_sub (input [16:0] a, input [17:0] b, input [34:0] c,
                        output [34:0] p);
  wire [16:0] m = a * b;
  assign p = c - m;
endmodule

// Same truncated product, with C subtracted from it. MULT_RSUB_C was wrong on
// 3000 of 3000 vectors.
module dspv4_trunc_rsub (input [16:0] a, input [17:0] b, input [34:0] c,
                         output [34:0] p);
  wire [16:0] m = a * b;
  assign p = m - c;
endmodule

// The adder's operands are both 17 bits, so the adder reads nothing above the
// truncated product -- but the sum keeps its carry, and that one bit is where
// the full product shows through: 1523 of 3000 vectors wrong. A guard that
// only compares the adder's operand width against the product misses this
// shape; the width that matters is the result's.
module dspv4_trunc_carry (input [16:0] a, input [17:0] b, input [16:0] c,
                          output [17:0] p);
  wire [16:0] m = a * b;
  assign p = m + c;
endmodule

// A truncated product accumulated at full width. The accumulator bank sits
// behind the same ALU, so MULT_ACC adds the whole product every cycle:
// 2000 of 2000 cycles wrong. The accumulator has to stay in fabric.
module dspv4_trunc_macc (input clk, input rst, input [16:0] a, input [17:0] b,
                         output reg [34:0] p);
  wire [16:0] m = a * b;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + m;
endmodule

// A truncated product through a product register, then added at full width.
// The M bank registers the multiplier's full output, so MULT_ADD_C with an M
// register was wrong on 2000 of 2000 cycles. The register itself still fits in
// the DSP: without the adder it is the result register, and P holds it.
module dspv4_trunc_mreg (input clk, input [16:0] a, input [17:0] b,
                         input [34:0] c, output [34:0] p);
  wire [16:0] m = a * b;
  reg [16:0] mr;
  always @(posedge clk) mr <= m;
  assign p = mr + c;
endmodule

// The three-input accumulate, with the product truncated. MULT_ACC_C was
// wrong on 2000 of 2000 cycles.
module dspv4_trunc_macc_c (input clk, input rst, input [16:0] a,
                           input [17:0] b, input [34:0] c,
                           output reg [34:0] p);
  wire [16:0] m = a * b;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + m + c;
endmodule

// A signed truncated product added at full width into an output register.
// Sign extension of the kept bits is not the full product either: 3000 of
// 3000 vectors wrong combinationally, 2000 of 2000 cycles with the register.
module dspv4_trunc_regout (input clk, input signed [16:0] a,
                           input signed [17:0] b, input signed [34:0] c,
                           output reg signed [34:0] p);
  wire signed [16:0] m = a * b;
  always @(posedge clk) p <= m + c;
endmodule

// The same truncated product, but the sum is no wider than it. The low 17
// bits of a sum depend only on the low 17 bits of its operands, so the DSP's
// full product makes no difference here: 0 of 3000 vectors wrong, and the
// shape must keep folding.
module dspv4_trunc_narrow (input [16:0] a, input [17:0] b, input [16:0] c,
                           output [16:0] p);
  wire [16:0] m = a * b;
  assign p = m + c;
endmodule

// A truncated product accumulated at its own width: exact in the DSP, 0 of
// 2000 cycles wrong, and the accumulator must still go into the bank.
module dspv4_trunc_narrow_macc (input clk, input rst, input [16:0] a,
                                input [17:0] b, output reg [16:0] p);
  wire [16:0] m = a * b;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + m;
endmodule

// A truncated product through a product register, added at its own width:
// exact in the DSP, 0 of 2000 cycles wrong, and the M register must still be
// absorbed together with the adder.
module dspv4_trunc_narrow_mreg (input clk, input [16:0] a, input [17:0] b,
                                input [16:0] c, output [16:0] p);
  wire [16:0] m = a * b;
  reg [16:0] mr;
  always @(posedge clk) mr <= m;
  assign p = mr + c;
endmodule
