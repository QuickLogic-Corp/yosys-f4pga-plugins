// The pre-adder's OUTPUT register -- the DSP's AD stage.
//
// The flop sits between the adder and the multiplier, so the multiplier's
// operand is its Q rather than the adder's Y. Until the pattern indexed
// through it the pre-adder was not inferred at all and the addition stayed in
// fabric, with nothing logged, because the shape was never offered.
//
// Both paths, because they are separate matches in the pattern. The second
// block's other operand is 32 bits, so it must take the 32-bit A port and the
// sum is pushed onto the B path.
//
// Resetless on purpose. QL_DSP4_AD_DFFR_32 takes the cell-wide RSTN, which
// this path does not wire, so a resettable AD register is left outside --
// dspv4_preadd_adreg_rst pins that.
//
// The results are combinational so this test measures the AD bank and nothing
// else: the only flops in the design are the two that have to move inside.
module dspv4_preadd_adreg (input clk,
                           input signed [15:0] d, input signed [15:0] a,
                           input signed [15:0] b,
                           output signed [32:0] p,
                           input signed [15:0] wide_d, input signed [15:0] wide_a,
                           input signed [31:0] wide_b,
                           output signed [48:0] wide_p);
  reg signed [16:0] ad, wide_ad;
  assign p = ad * b;
  assign wide_p = wide_ad * wide_b;
  always @(posedge clk) begin
    ad      <= d + a;
    wide_ad <= wide_d + wide_a;
  end
endmodule
