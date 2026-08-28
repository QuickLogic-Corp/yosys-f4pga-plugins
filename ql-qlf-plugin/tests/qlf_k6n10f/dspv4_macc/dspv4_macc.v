// Reset to zero: the DSP accumulator resets to zero and cannot express any
// other reset value, so an unreset or non-zero-reset accumulator stays soft.
module dspv4_macc (input clk, input rst, input signed [17:0] a,
                   input signed [17:0] b, output reg signed [35:0] p);
  always @(posedge clk or posedge rst)
    if (rst) p <= 0; else p <= p + a * b;
endmodule
