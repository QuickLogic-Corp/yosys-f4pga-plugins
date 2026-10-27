// Cross-path: the pre-adder result multiplies one of its own inputs.
// Phase 4, REQ-C1.
//
//        d ---->[ + ]---- AD ----> A port of the multiplier
//        a --+-->[ ]                          |
//            |                                v
//            +-------------------------> B port
//
// `a` is read twice -- once by the pre-adder, once by the multiplier's other
// port. That fanout is the whole point of the test. The DSP does this in one
// cell; the risk is that the pass sees the second reader and declines to fuse
// the adder, which leaves a 17-bit carry chain in fabric and reports nothing.
//
// The mode table calls this XPATH_A, but the pass emits PREADD_A_MULT_B --
// the two control words drive the same hardware for this RTL, and the PREADD
// word is what the operand-assignment logic naturally picks. The assertions
// below are on the RESULT (one DSP, no fabric adder), not the mode name, so
// they stay true if that choice is ever revisited.
//
// Signed because the multiplier is Baugh-Wooley signed. d + a needs 17 bits,
// well inside AD's 32 on the A path; `a` at 16 bits fits the 18-bit B port.
module dspv4_xpath (input signed [15:0] d, input signed [15:0] a,
                    output signed [33:0] p);
  assign p = (d + a) * a;
endmodule
