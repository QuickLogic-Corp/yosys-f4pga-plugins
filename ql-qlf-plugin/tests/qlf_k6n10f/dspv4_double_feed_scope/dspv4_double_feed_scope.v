// Shapes that share an operand between ports and must keep their modes.
// The double-feed check refuses a cell that uses its pre-adder only when the
// pre-adder's input mux would see one signal on both the A and the B path.
// The first three do not use the pre-adder. The last two do, safely.
//
//   sq     x * x: x on A and B with the pre-adder off
//   sqc    x * x + c: the same, with the ALU adding C
//   abpa   a * b + a: a on A and on C, and C never reaches the pre-adder
//   pipe   s_r * a_r, with s_r <= d + a and a_r <= a. a is on ports A and B,
//          but B absorbs a_r's register, so the mux sees a and a_r: two
//          signals. It programs (measured). PREADD_A_MULT_B
//   aa     (a + a) * b: a on ports D and A. D reaches the pre-adder by its
//          own wire, not through the mux. PREADD_A_MULT_B
module dspv4_double_feed_scope (
    input clk,
    input signed [15:0] sq_x, output signed [31:0] sq_y,
    input signed [15:0] sqc_x, input signed [31:0] sqc_c, output signed [32:0] sqc_y,
    input signed [15:0] abpa_a, input signed [15:0] abpa_b, output signed [32:0] abpa_y,
    input signed [15:0] pipe_d, input signed [15:0] pipe_a, output signed [33:0] pipe_p,
    input signed [15:0] aa_a, input signed [15:0] aa_b, output signed [32:0] aa_p
);
  assign sq_y = sq_x * sq_x;
  assign sqc_y = sqc_x * sqc_x + sqc_c;
  assign abpa_y = abpa_a * abpa_b + abpa_a;

  reg signed [16:0] pipe_s_r;
  reg signed [15:0] pipe_a_r;
  always @(posedge clk) begin
    pipe_s_r <= pipe_d + pipe_a;
    pipe_a_r <= pipe_a;
  end
  assign pipe_p = pipe_s_r * pipe_a_r;

  assign aa_p = (aa_a + aa_a) * aa_b;
endmodule
