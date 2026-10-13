// A signed truncated product added at full width into an output register.
// Sign extension of the kept bits is not the full product either: 3000 of
// 3000 vectors wrong combinationally, 2000 of 2000 cycles with the register.
module dspv4_trunc_regout (input clk, input signed [16:0] a,
                           input signed [17:0] b, input signed [34:0] c,
                           output reg signed [34:0] p);
  wire signed [16:0] m = a * b;
  always @(posedge clk) p <= m + c;
endmodule
