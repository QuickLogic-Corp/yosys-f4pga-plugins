// A truncated product accumulated at its own width: exact in the DSP, 0 of
// 2000 cycles wrong, and the accumulator must still go into the bank.
module dspv4_trunc_narrow_macc (input clk, input rst, input [16:0] a,
                                input [17:0] b, output reg [16:0] p);
  wire [16:0] m = a * b;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + m;
endmodule
