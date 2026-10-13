// The same truncated product, but the sum is no wider than it. The low 17
// bits of a sum depend only on the low 17 bits of its operands, so the DSP's
// full product makes no difference here: 0 of 3000 vectors wrong, and the
// shape must keep folding.
module dspv4_trunc_narrow (input [16:0] a, input [17:0] b, input [16:0] c,
                           output [16:0] p);
  wire [16:0] m = a * b;
  assign p = m + c;
endmodule
