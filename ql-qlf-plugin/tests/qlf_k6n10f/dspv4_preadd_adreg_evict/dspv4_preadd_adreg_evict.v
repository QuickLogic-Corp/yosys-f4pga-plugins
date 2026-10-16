// The AD register has no reset, but another register in the same cell does.
//
// QL_DSP4_AD_DFFR_32's R pin is the cell-wide RSTN, shared with the operand
// banks. Wiring RSTN for the B register would also reset the AD bank, which
// this RTL never asks for.
//
// Rather than give up the pre-adder, the pass gives up the B register chain.
// Those flops go to fabric -- which is where they ended up anyway when we
// refused the pre-adder and the matcher re-offered the multiply without it.
// So the eviction costs no flops and saves 17 carry cells.
//
// dspv4_preadd_adreg_rst pins the other half: an AD register carrying its own
// reset, which never matches the pattern at all.
module dspv4_preadd_adreg_evict (input clk, rstn,
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
