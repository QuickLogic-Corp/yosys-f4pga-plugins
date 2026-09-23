// A multiply-add chain three deep: two adders in series with no accumulator
// flop anywhere. This is the shape the cascade_* designs in the aurora2 DSP
// suite are built from.
module dspv4_mult_add_chain (input signed [17:0] a1, a2, a3, b,
                             output signed [37:0] p);
  wire signed [35:0] m1 = a1 * b;
  wire signed [36:0] s1 = a2 * b + m1;
  assign p = a3 * b + s1;
endmodule
