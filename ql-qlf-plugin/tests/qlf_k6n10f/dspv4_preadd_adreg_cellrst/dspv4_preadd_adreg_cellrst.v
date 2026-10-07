// The AD register itself has no reset, but another register absorbed into the
// same cell does.
//
// QL_DSP4_AD_DFFR_32's R pin is the cell-wide RSTN, shared with the operand
// banks. Wiring RSTN for the B operand register would reset the AD bank as
// well, which this RTL never asks for -- so the AD register is refused here
// too, for a reason the $dff restriction alone does not cover.
//
// dspv4_preadd_adreg_rst pins the other half: an AD register that carries its
// own reset.
module dspv4_preadd_adreg_cellrst (input clk, rstn,
                                   input signed [15:0] d, input signed [15:0] a,
                                   input signed [15:0] b,
                                   output signed [32:0] p);
  reg signed [16:0] ad;
  reg signed [15:0] b_stage;
  assign p = ad * b_stage;
  always @(posedge clk) begin
    ad <= d + a;
    if (!rstn) b_stage <= 0;
    else       b_stage <= b;
  end
endmodule
