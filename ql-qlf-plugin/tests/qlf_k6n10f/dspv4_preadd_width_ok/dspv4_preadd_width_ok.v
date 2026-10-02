// Width safety, the passing case. Phase 4, REQ-D2.
//
// The pre-adder sum reaches the multiplier as AD. On the A path AD keeps all
// 32 bits; on the B path it is truncated to 18, with no saturation and no
// flag -- ffb 4.2.5 removed the saturation. So the B path is the one that
// needs a proof, and these tests force it.
//
// Forcing it: `b` is 32 bits, which cannot fit the 18-bit multiplier port, so
// the A path is unavailable and the sum has to go to the B path. That is what
// makes this a width test rather than a repeat of dspv4_preadd_a.
//
// d + a with 16-bit signed operands needs 17 bits. AD's B path holds 18, so
// this fits with a bit to spare and must infer.
module dspv4_preadd_width_ok (input signed [15:0] d, input signed [15:0] a,
                              input signed [31:0] b,
                              output signed [49:0] p);
  assign p = (d + a) * b;
endmodule
