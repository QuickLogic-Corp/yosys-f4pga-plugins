// Operand registers one deep on A and two deep on B. The DSP can hold two
// stages per operand, but absorbing two on B and one on A would present the
// multiplier with operands from different cycles, so only the common depth of
// one moves inside and B's surplus flop stays in fabric.
module dspv4_mult_regin (input clk, rstn,
                         input signed [17:0] a, input signed [17:0] b,
                         output signed [35:0] p);
  reg signed [17:0] a1, b1, b2;
  always @(posedge clk or negedge rstn)
    if (!rstn) begin a1 <= 0; b1 <= 0; b2 <= 0; end
    else       begin a1 <= a;  b1 <= b;  b2 <= b1; end
  assign p = a1 * b2;
endmodule
