// The other direction: out <= a*b - out.
//
// A*B - P is the reverse-subtract direction, which the ALU computes as
// ~Z + (W+X+Y) + CIN -- correct only at CIN=1. ql_dspv4 never drives the CIN
// port and the leaf coerces an undriven CIN to 0, so taking this shape would be
// off by one. It stays soft until CIN is wired.
module dspv4_macc_rsub (input clk, input rst, input signed [17:0] a,
                        input signed [17:0] b, output reg signed [35:0] p);
  // Synchronous reset: every DSP register bank resets synchronously, so an
  // async-reset accumulator cannot be absorbed at all and would test nothing.
  always @(posedge clk)
    if (rst) p <= 0; else p <= a * b - p;
endmodule
