// Pre-adder with a fused addend -- the shape dsp_preadder_multadd is built on,
// and the one Phase 4 step 1 deliberately refused. (D + A) * B + C is one cell:
// pre-adder, multiplier and ALU all inside the DSP.
//
// The subtract direction is covered separately, in dspv4_preadd_sub_fused.
module dspv4_preadd_addc (input signed [14:0] d, input signed [14:0] a,
                          input signed [14:0] b, input signed [33:0] c,
                          output signed [33:0] p);
  assign p = c + (a * (d + b));
endmodule
