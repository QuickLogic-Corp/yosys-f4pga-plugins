// Operand registers one deep on A and two deep on B. Each port has its own
// register stages inside the DSP, so each absorbs its own depth and nothing is
// left in fabric: A takes AREG1, B takes BREG0+BREG1. The DSP is not equalising
// delays, it is reproducing the ones the RTL asked for.
//
// The reset is synchronous because that is the only reset the DSP flops can
// take from fabric -- leaf R comes from rstn_i off the routable IC0 bus, while
// the async pin is chip-global with Fc = 0.
module dspv4_mult_regin (input clk, rstn,
                         input signed [17:0] a, input signed [17:0] b,
                         output signed [35:0] p);
  reg signed [17:0] a1, b1, b2;
  always @(posedge clk)
    if (!rstn) begin a1 <= 0; b1 <= 0; b2 <= 0; end
    else       begin a1 <= a;  b1 <= b;  b2 <= b1; end
  assign p = a1 * b2;
endmodule
