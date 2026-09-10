// Accumulate with a subtract: out <= out - a*b.
//
// P - A*B is the ALU's own subtract direction (Z - (W+X+Y)) over MULT_ACC's
// operand muxes, so it needs no extra hardware -- only the MULT_ACC_SUB control
// word, which the spreadsheet did not enumerate because it pairs ALUMODE=11
// with the A:B path rather than the multiplier path.
module dspv4_macc_sub (input clk, input rst, input signed [17:0] a,
                       input signed [17:0] b, output reg signed [35:0] p);
  // Synchronous reset: every DSP register bank resets synchronously, so an
  // async-reset accumulator cannot be absorbed at all and would test nothing.
  always @(posedge clk)
    if (rst) p <= 0; else p <= p - a * b;
endmodule
