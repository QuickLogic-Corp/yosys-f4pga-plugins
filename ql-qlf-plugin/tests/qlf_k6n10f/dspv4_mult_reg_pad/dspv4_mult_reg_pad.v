// Second register pads with data, not sign. Must not be absorbed.
//
// The relaxed index on output_flop2 only compares the low bits, so this
// passes the pattern. Bit 36 of p is m[0] in RTL; the DSP's P register would
// put the sign bit there.
module dspv4_mult_reg_pad (input clk, input signed [17:0] a, input signed [17:0] b,
                           output reg signed [36:0] p);
  reg signed [35:0] m;
  always @(posedge clk) begin
    m <= a * b;
    p <= {m[0], m};
  end
endmodule
