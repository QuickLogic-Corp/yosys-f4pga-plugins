// Asymmetric depths: D is registered twice, A once.
//
// Each port has its own bank depth inside the DSP, so each takes its own and
// the surplus stays outside. D's bank is one stage, so the outer D register is
// left in fabric; A's bank is two stages, so its single register goes in.
//
// The DSP is not equalising delays -- it is reproducing the ones the RTL asked
// for. Absorbing both D stages would move D a cycle earlier than A; dropping
// the surplus would lose a cycle outright. Both compute the wrong number and
// neither raises anything.
module dspv4_preadd_dreg_asym (input clk,
                               input signed [15:0] d, input signed [15:0] a,
                               input signed [15:0] b,
                               output signed [32:0] p);
  reg signed [15:0] d_s0, d_s1, a_s0;
  assign p = (d_s1 + a_s0) * b;
  always @(posedge clk) begin
    d_s0 <= d;
    d_s1 <= d_s0;
    a_s0 <= a;
  end
endmodule
