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
//   pipe2  (d1 + a1) * a2, with a2 <= a1 <= a: one stage on the adder side,
//          two on the multiply side. PREADD_A_MULT_B
//   two_en (d + a_r) * a_r2, two one-stage registers of a, each its own
//          enable. PREADD_A_MULT_B
//   mulr   (d + a) * a1: only the multiply side is registered.
//          PREADD_A_MULT_B
//   addr   (d + a1) * a: only the adder side is registered, the mirror of
//          mulr. PREADD_A_MULT_B
//   cst    (d + 12345) * 12345: the same constant on both sides of the
//          pre-adder's input mux. A constant has no wire, so it is not a
//          shared operand (OQ-X3). PREADD_A_MULT_B, the constant on A and B.
module dspv4_double_feed_scope (
    input clk,
    input signed [15:0] sq_x, output signed [31:0] sq_y,
    input signed [15:0] sqc_x, input signed [31:0] sqc_c, output signed [32:0] sqc_y,
    input signed [15:0] abpa_a, input signed [15:0] abpa_b, output signed [32:0] abpa_y,
    input signed [15:0] pipe_d, input signed [15:0] pipe_a, output signed [33:0] pipe_p,
    input signed [15:0] aa_a, input signed [15:0] aa_b, output signed [32:0] aa_p,
    input signed [15:0] pipe2_d, input signed [15:0] pipe2_a, output signed [33:0] pipe2_p,
    input two_en_en1, input two_en_en2,
    input signed [15:0] two_en_d, input signed [15:0] two_en_a, output signed [33:0] two_en_p,
    input signed [15:0] mulr_d, input signed [15:0] mulr_a, output signed [33:0] mulr_p,
    input signed [15:0] addr_d, input signed [15:0] addr_a, output signed [33:0] addr_p,
    input signed [15:0] cst_d, output signed [32:0] cst_p
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

  reg signed [15:0] pipe2_d1, pipe2_a1, pipe2_a2;
  always @(posedge clk) begin
    pipe2_d1 <= pipe2_d;
    pipe2_a1 <= pipe2_a;
    pipe2_a2 <= pipe2_a1;
  end
  assign pipe2_p = (pipe2_d1 + pipe2_a1) * pipe2_a2;

  reg signed [15:0] two_en_a_r, two_en_a_r2;
  always @(posedge clk) begin
    if (two_en_en1) two_en_a_r <= two_en_a;
    if (two_en_en2) two_en_a_r2 <= two_en_a;
  end
  assign two_en_p = (two_en_d + two_en_a_r) * two_en_a_r2;

  reg signed [15:0] mulr_a1;
  always @(posedge clk) begin
    mulr_a1 <= mulr_a;
  end
  assign mulr_p = (mulr_d + mulr_a) * mulr_a1;

  reg signed [15:0] addr_a1;
  always @(posedge clk) begin
    addr_a1 <= addr_a;
  end
  assign addr_p = (addr_d + addr_a1) * addr_a;

  assign cst_p = (cst_d + 16'sd12345) * 16'sd12345;
endmodule
