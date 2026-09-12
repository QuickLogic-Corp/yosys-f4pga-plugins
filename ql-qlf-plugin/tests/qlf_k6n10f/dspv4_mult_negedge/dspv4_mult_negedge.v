// A falling-edge output register. Every DSP register bank is rising-edge --
// dsp4_logical_map.v instantiates QL_DSP4_*_DFFRE_* with .clk(CLK) and no
// inversion -- so this register cannot move into the DSP.
//
// It used to be absorbed with its clock wired straight through, re-timing the
// design onto the opposite edge with nothing in the log to say so. The multiply
// should still reach a DSP, with the negedge flop left in fabric.
module dspv4_mult_negedge (input clk, input signed [17:0] a,
                           input signed [17:0] b,
                           output reg signed [35:0] p);
  always @(negedge clk) p <= a * b;
endmodule
