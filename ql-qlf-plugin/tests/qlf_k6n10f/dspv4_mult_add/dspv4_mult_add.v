module dspv4_mult_add (input signed [17:0] a, input signed [17:0] b,
                       input signed [35:0] c, output signed [35:0] p);
  assign p = a * b + c;
endmodule
