// B path: b is 32 bits, so it must take the 32-bit A port and the sum is
// pushed onto the B path, where AD is truncated to 18.
module dspv4_preadd_b (input signed [15:0] d, input signed [15:0] a,
                       input signed [31:0] b,
                       output signed [48:0] p);
  assign p = (d + a) * b;
endmodule
