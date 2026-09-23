// Operands are signed: the DSP multiplier is signed, so an unsigned 18-bit
// value needs a spare bit and is left soft by design.
module dspv4_mult (input signed [17:0] a, input signed [17:0] b,
                   output signed [35:0] p);
  assign p = a * b;
endmodule
