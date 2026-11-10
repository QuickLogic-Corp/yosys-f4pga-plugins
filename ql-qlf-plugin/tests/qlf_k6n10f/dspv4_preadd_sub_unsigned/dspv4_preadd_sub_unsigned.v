// Unsigned pre-adder subtract. Refused when the product is wider than the
// subtract, folded when it is not.
//
// Verilog wraps an unsigned `d - a` at the subtract's own width; the DSP's
// pre-adder is signed and goes negative. The two values are congruent modulo
// that width, and multiplication preserves congruence, so they agree only
// while the product stays inside it. One bit past and the sign shows through.
//
//   g   the minuend narrow, the subtrahend at 31 bits, so the sum needs the
//       pre-adder's full 32-bit limit. An unsigned sum normally needs one
//       more bit than that to count its own top bit as a sign; a subtract's
//       range already fits without it, which is the only reason this one
//       still fits 32 instead of needing 33. Read back at the subtract's own
//       width, like n, so the congruence holds and it is safe to fold.
module dspv4_preadd_sub_unsigned (
    // 9-bit subtract, 35-bit product -- must be refused
    input  [15:0] w_d, input [15:0] w_a, input [17:0] w_b,
    output [34:0] w_p,
    // 9-bit subtract, 9-bit product -- safe, must fold
    input  [7:0]  n_d, input [7:0]  n_a, input [7:0]  n_b,
    output [8:0]  n_p,
    // 32-bit subtract (31-bit subtrahend), 32-bit product -- safe, must fold
    input  [25:0] g_d, input [30:0] g_x, input [16:0] g_b,
    output [31:0] g_p
);
  wire [16:0] w_s = w_d - w_a;
  assign w_p = w_s * w_b;

  wire [8:0] n_s = n_d - n_a;
  assign n_p = n_s * n_b;

  wire [31:0] g_s = g_d - g_x;
  assign g_p = g_s * g_b;
endmodule
