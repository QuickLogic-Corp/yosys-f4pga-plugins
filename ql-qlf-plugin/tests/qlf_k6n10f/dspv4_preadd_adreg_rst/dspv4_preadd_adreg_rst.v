// The same shape as dspv4_preadd_adreg, with one difference: the AD register
// has a reset.
//
// QL_DSP4_AD_DFFR_32's R pin is the cell-wide RSTN, which the pre-adder path
// does not wire, so absorbing this flop would drop its reset silently -- the
// netlist still synthesises, packs and routes, and only the values are wrong.
// Refusing is the correct answer, and this test is what keeps it refused.
//
// The refusal costs the pre-adder, not the register: the flop is then an
// ordinary A-operand register, and the A bank does have a reset.
module dspv4_preadd_adreg_rst (input clk, rstn,
                               input signed [15:0] d, input signed [15:0] a,
                               input signed [15:0] b,
                               output signed [32:0] p);
  reg signed [16:0] ad;
  assign p = ad * b;
  always @(posedge clk)
    if (!rstn) ad <= 0;
    else       ad <= d + a;
endmodule
