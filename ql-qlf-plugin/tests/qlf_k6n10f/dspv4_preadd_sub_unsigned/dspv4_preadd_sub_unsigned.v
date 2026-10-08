// Unsigned pre-adder subtract. Refused when the product is wider than the
// subtract, folded when it is not.
//
// Verilog wraps an unsigned `d - a` at the subtract's own width; the DSP's
// pre-adder is signed and goes negative. The two values are congruent modulo
// that width, and multiplication preserves congruence, so they agree only
// while the product stays inside it. One bit past and the sign shows through.
module dspv4_preadd_sub_unsigned (
    // 9-bit subtract, 35-bit product -- must be refused
    input  [15:0] w_d, input [15:0] w_a, input [17:0] w_b,
    output [34:0] w_p,
    // 9-bit subtract, 9-bit product -- safe, must fold
    input  [7:0]  n_d, input [7:0]  n_a, input [7:0]  n_b,
    output [8:0]  n_p
);
  wire [16:0] w_s = w_d - w_a;
  assign w_p = w_s * w_b;

  wire [8:0] n_s = n_d - n_a;
  assign n_p = n_s * n_b;
endmodule
