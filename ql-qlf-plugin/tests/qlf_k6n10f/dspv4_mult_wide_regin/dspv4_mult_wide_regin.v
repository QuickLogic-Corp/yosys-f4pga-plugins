// A 32x32 multiply is wider than one DSP, so mul2dsp splits it across two. The
// split cuts the B operand into two 18-bit halves, which means neither DSP sees
// the whole b2 register -- the case operand-register absorption used to refuse.
//
// A is not cut: both DSPs take all 32 bits of a2, so A absorbed even before the
// fix. The test pins both, so a regression on either side is visible.
module dspv4_mult_wide_regin (input clk, rstn,
                              input signed [31:0] a, input signed [31:0] b,
                              output signed [63:0] p);
  reg signed [31:0] a1, a2, b1, b2;
  always @(posedge clk)
    if (!rstn) begin a1 <= 0; a2 <= 0; b1 <= 0; b2 <= 0; end
    else       begin a1 <= a; a2 <= a1; b1 <= b; b2 <= b1; end
  assign p = a2 * b2;
endmodule
