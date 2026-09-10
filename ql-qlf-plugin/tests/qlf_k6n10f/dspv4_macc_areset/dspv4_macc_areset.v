// An async-reset accumulator cannot be absorbed.
//
// Every DSP register bank resets synchronously (dsp4_logical_map.v wires .R to
// RSTN on QL_DSP4_*_DFFRE_*), so there is nowhere in the DSP to put a flop that
// resets asynchronously. The multiply still becomes a DSP; only the accumulate
// stays outside, with the DSP's C port carrying the fabric value back in.
module dspv4_macc_areset (input clk, input rst, input signed [17:0] a,
                          input signed [17:0] b, output reg signed [35:0] p);
  always @(posedge clk or posedge rst)
    if (rst) p <= 0; else p <= p + a * b;
endmodule
