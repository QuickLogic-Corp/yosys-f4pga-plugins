// The same shape as dspv4_preadd_adreg, but the AD register has a reset.
//
// QL_DSP4_AD_DFFR_32 takes the cell-wide RSTN, which the pre-adder path does
// not wire, so absorbing this flop would drop its reset silently. Measured
// before the restriction: 158 of 300 unsigned vectors wrong, with synthesis,
// packing and routing all clean.
module dspv4_preadd_adreg_rst (input clk, rst,
                               input signed [14:0] m, input signed [14:0] a,
                               input signed [15:0] b,
                               output reg signed [33:0] p);
  reg signed [15:0] ad;
  always @(posedge clk) if (rst) ad <= 0; else ad <= m + a;
  always @(posedge clk) if (rst) p  <= 0; else p  <= ad * b;
endmodule
