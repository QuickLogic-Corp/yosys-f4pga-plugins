// The other accumulate direction: out <= a*b - out.
//
// A*B - P is the reverse-subtract direction, which the ALU computes as
// ~Z + (W+X+Y) + CIN -- correct only at CIN=1. ql_dspv4 ties CIN high for every
// ALUMODE=01 mode, so this maps to MULT_ACC_RSUB. Proved equivalent over all
// inputs by verify_equiv.py (shape mult_acc_rsub_srst), which is the check that
// matters here: an off-by-one would still look right in a cell count.
module dspv4_macc_rsub (input clk, input rst, input signed [17:0] a,
                        input signed [17:0] b, output reg signed [35:0] p);
  // Synchronous reset: every DSP register bank resets synchronously, so an
  // async-reset accumulator cannot be absorbed at all and would test nothing.
  always @(posedge clk)
    if (rst) p <= 0; else p <= a * b - p;
endmodule
