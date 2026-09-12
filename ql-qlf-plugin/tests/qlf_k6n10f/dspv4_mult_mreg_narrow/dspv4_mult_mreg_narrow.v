// An M-stage register whose D is WIDER than the product.
//
// The register is declared 40 bits while the product is 36, so D arrives as the
// product sign-extended by 4 bits rather than as the product signal itself. An
// exact SigSpec comparison in the pattern therefore never offers the flop, and
// it stays in fabric together with the adder behind it.
//
// This is not a contrived shape. wreduce produces it from ordinary RTL: it
// narrows the multiply when the upper product bits reach nothing downstream but
// leaves the register at its declared width. gng_smul_16_18_sadd_37 hits it --
// a 34-bit prod register against a 32-bit narrowed product -- which is why the
// register absorbed when that module was synthesised alone and stayed in fabric
// inside the full gng design. The width difference is written out explicitly
// here so the test does not depend on wreduce making a particular choice.
module dspv4_mult_mreg_narrow (input clk,
                               input signed [17:0] a, input signed [17:0] b,
                               input signed [39:0] c,
                               output signed [40:0] p);
  wire signed [35:0] prod_w = a * b;   // 36-bit product
  reg  signed [39:0] prod;             // 40-bit register: D = sext(prod_w, 40)
  always @(posedge clk) prod <= prod_w;
  assign p = c + prod;
endmodule
