// A pipeline register on the product, with an active-low asynchronous reset --
// the register style the cascade_* designs in the aurora2 DSP suite use.
module dspv4_mult_regout (input clk, rstn,
                          input signed [17:0] a, input signed [17:0] b,
                          output reg signed [35:0] p);
  always @(posedge clk or negedge rstn)
    if (!rstn) p <= 0;
    else       p <= a * b;
endmodule
