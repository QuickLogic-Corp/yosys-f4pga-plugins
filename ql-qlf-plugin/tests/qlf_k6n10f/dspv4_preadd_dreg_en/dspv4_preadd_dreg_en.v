// Clock enables on the pre-adder's input register, and the eviction that
// happens when a cell wants more enables than the DSP has.
//
// The DSP routes three distinct clock enables. Past that the pass drops ports
// narrowest-first -- B at 18 bits, then D at 27 -- so a four-enable cell loses
// B and keeps D. Neither shape had a test.
module dspv4_preadd_dreg_en (
    input clk,
    // One enable on D alone: absorbed, and the enable goes with it.
    input en0, input signed [15:0] d0, input signed [15:0] a0,
    input signed [15:0] b0, output signed [32:0] p0,
    // Four distinct enables: one too many, so B is evicted and D stays.
    input en_d, input en_a, input en_b, input en_p,
    input signed [15:0] d1, input signed [15:0] a1, input signed [15:0] b1,
    output reg signed [32:0] p1
);
  reg signed [15:0] d0_q;
  reg signed [15:0] d1_q, a1_q, b1_q;

  assign p0 = (d0_q + a0) * b0;

  always @(posedge clk) begin
    if (en0)  d0_q <= d0;
    if (en_d) d1_q <= d1;
    if (en_a) a1_q <= a1;
    if (en_b) b1_q <= b1;
    if (en_p) p1   <= (d1_q + a1_q) * b1_q;
  end
endmodule
