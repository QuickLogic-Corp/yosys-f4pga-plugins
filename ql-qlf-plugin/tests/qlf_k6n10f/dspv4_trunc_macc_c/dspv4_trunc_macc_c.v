// The three-input accumulate, with the product truncated. MULT_ACC_C was
// wrong on 2000 of 2000 cycles.
module dspv4_trunc_macc_c (input clk, input rst, input [16:0] a,
                           input [17:0] b, input [34:0] c,
                           output reg [34:0] p);
  wire [16:0] m = a * b;
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + m + c;
endmodule
