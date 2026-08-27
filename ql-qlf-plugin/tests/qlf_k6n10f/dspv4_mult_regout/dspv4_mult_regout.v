// A pipeline register on the product. The reset is synchronous: leaf R is
// driven from rstn_i (ACCRSTN for the accumulator) off the routable IC0 bus,
// so a synchronous reset is the only one the DSP can absorb. The register must
// end up in the DSP's accumulator bank, leaving no flop in fabric at all --
// that is the assertion with teeth.
module dspv4_mult_regout (input clk, rstn,
                          input signed [17:0] a, input signed [17:0] b,
                          output reg signed [35:0] p);
  always @(posedge clk)
    if (!rstn) p <= 0;
    else       p <= a * b;
endmodule
