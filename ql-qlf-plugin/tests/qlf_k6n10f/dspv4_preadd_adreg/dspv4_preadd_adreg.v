// The pre-adder's OUTPUT register -- the DSP's AD stage.
//
// The flop sits between the adder and the multiplier, so the multiplier's
// operand is its Q rather than the adder's Y. Before the pattern indexed
// through it, the pre-adder was not inferred at all and the addition stayed in
// fabric -- with nothing logged, because the shape was never offered.
//
// Resetless on purpose: QL_DSP4_AD_DFFR_32 takes the cell-wide RSTN, which the
// pre-adder path does not wire, so a resettable AD register is deliberately
// left outside. dspv4_preadd_adreg_rst pins that.
module dspv4_preadd_adreg (input clk,
                           input signed [14:0] m, input signed [14:0] a,
                           input signed [15:0] b,
                           output reg signed [33:0] p);
  reg signed [15:0] ad;
  always @(posedge clk) ad <= m + a;
  always @(posedge clk) p  <= ad * b;
endmodule
