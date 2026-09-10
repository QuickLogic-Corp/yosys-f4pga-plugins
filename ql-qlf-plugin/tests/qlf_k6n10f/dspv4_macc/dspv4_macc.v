// Reset to zero: the DSP accumulator resets to zero and cannot express any
// other reset value, so an unreset or non-zero-reset accumulator stays soft.
//
// The reset must also be SYNCHRONOUS. Every DSP register bank resets
// synchronously, so an async-reset accumulator cannot be absorbed -- see
// dspv4_macc_areset, which pins that. This test read `posedge clk or posedge
// rst` until 2026-09-10 and so left its accumulator in fabric while asserting
// only that $add was gone, which post-synth it is either way.
module dspv4_macc (input clk, input rst, input signed [17:0] a,
                   input signed [17:0] b, output reg signed [35:0] p);
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + a * b;
endmodule
