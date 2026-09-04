// An output register with a non-zero power-up value. The DSP's accumulator bank
// has none to set -- the leaf is `if (!R) Q <= 0; else if (E) Q <= D`, with no
// initial block -- so this register cannot move into the DSP.
//
// The multiply should still reach a DSP, with the flop left in fabric carrying
// its init.
module dspv4_mult_init (input clk, input signed [17:0] a,
                        input signed [17:0] b,
                        output reg signed [35:0] p);
  initial p = 36'h123456789;
  always @(posedge clk) p <= a * b;
endmodule
