// B path, subtract direction.
module dspv4_preadd_b_sub (input signed [15:0] d, input signed [15:0] a,
                           input signed [31:0] b,
                           output signed [48:0] p);
  assign p = (d - a) * b;
endmodule
