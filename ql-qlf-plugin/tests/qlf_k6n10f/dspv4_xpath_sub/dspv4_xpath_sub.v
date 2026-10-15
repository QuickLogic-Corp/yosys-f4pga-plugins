// Cross-path, subtract direction: (d - a) * a. Phase 2, REQ-A2.
//
// Same shape as dspv4_xpath with the pre-adder subtracting, which selects the
// PRESUB leaf instead of PREADD.
//
// Both operands are SIGNED, and that is load-bearing. An unsigned RTL
// subtract wraps at its own width where the DSP's pre-adder goes negative,
// so the two disagree for d < a. The pass refuses that fold when the product
// is wider than the subtract, which this shape would be, so an unsigned
// version of this module keeps its adder in fabric and is a different test.
module dspv4_xpath_sub (input signed [15:0] d, input signed [15:0] a,
                        output signed [33:0] p);
  assign p = (d - a) * a;
endmodule
