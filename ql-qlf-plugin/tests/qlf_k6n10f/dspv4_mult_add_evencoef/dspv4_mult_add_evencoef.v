// A sum of products whose last coefficient is divisible by four.
//
// Yosys builds the sum left-associatively, so the outermost adder can only be
// absorbed by the LAST product's DSP -- each of the three products has its own
// free C port, and the DSPs chain P -> C. C2 is -9876, and wreduce rewrites
// `z2 * -9876` as `(z2 * -2469) << 2`, which leaves the product two bits up
// inside that adder's operand with two constant zeros beneath it. C0 and C1 are
// odd, so their products stay in the low bits and their adder fuses.
module dspv4_mult_add_evencoef (input clk, input rst,
                                input signed [17:0] z0, z1, z2,
                                output signed [37:0] y);
  localparam signed [17:0] C0 =  18'sd12345;
  localparam signed [17:0] C1 = -18'sd23167;
  localparam signed [17:0] C2 = -18'sd9876;
  reg signed [37:0] y_r;
  always @(posedge clk) begin
    if (!rst) y_r <= 0;
    else      y_r <= z0 * C0 + z1 * C1 + z2 * C2;
  end
  assign y = y_r;
endmodule
