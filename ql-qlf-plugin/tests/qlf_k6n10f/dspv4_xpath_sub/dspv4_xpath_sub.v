// Cross-path, subtract direction: (d - a) * a. Phase 4, REQ-C1.
//
// Same shape as dspv4_xpath with the pre-adder subtracting, which selects the
// PRESUB leaf instead of PREADD.
//
// Both operands are SIGNED, and that is load-bearing rather than incidental.
// The DSP's pre-adder subtracts in two's complement and yields a signed
// result; an unsigned RTL subtract wraps instead. For d < a the two disagree,
// on roughly half of all operand pairs, and nothing downstream reports it.
// The pass refuses an unsigned pre-adder subtract for that reason, so an
// unsigned version of this module would legitimately keep its adder in fabric
// and is a different test.
module dspv4_xpath_sub (input signed [15:0] d, input signed [15:0] a,
                        output signed [33:0] p);
  assign p = (d - a) * a;
endmodule
