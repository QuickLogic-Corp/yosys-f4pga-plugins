// A truncated product accumulated at full width. The accumulator bank sits
// behind the same ALU, so MULT_ACC adds the whole product every cycle:
// 2000 of 2000 cycles wrong. The accumulator has to stay in fabric.
module dspv4_trunc_macc (input clk, input rst, input [16:0] a, input [17:0] b,
                         output reg [34:0] p);
  wire [16:0] m = a * b;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + m;
endmodule
