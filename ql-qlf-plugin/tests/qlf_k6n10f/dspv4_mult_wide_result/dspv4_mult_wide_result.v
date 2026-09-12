// A 64-bit accumulator. P is 50 bits wide, so this cannot be an absorbed
// accumulator -- the top 14 bits have nowhere to come from.
//
// It used to be absorbed anyway: the result was truncated to the port width and
// the rest of `p` was left with no driver, which write_verilog renders as
//   assign p = { 14'hxxxx, <acc>[49:0] };
// while the pass reported one inferred cell and `check` reported no problems.
// The multiply should still reach a DSP, with the accumulator in fabric.
module dspv4_mult_wide_result (input clk, input signed [17:0] a,
                               input signed [17:0] b,
                               output reg signed [63:0] p);
  always @(posedge clk) p <= p + a * b;
endmodule
