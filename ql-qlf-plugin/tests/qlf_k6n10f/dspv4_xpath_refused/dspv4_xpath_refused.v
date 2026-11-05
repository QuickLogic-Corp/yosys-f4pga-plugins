// Cross-path shapes that must not fold. Each keeps its multiply in a DSP and
// its pre-adder's work in fabric.
//
//   sub   (d - a) * a. No XPATH subtract word, and a is the subtrahend, so it
//         cannot move to port D. The only PREADD word puts a on A and B, which
//         the double-feed check refuses: MULT
//   alu   (d + a) * a + c. No XPATH word has an ALU term, and a PREADD word
//         would put a on A and B: MULT_ADD_C
//   acc   p <= p + (d + a) * a, the + p form of the same: MULT_ACC
//   subc  (d - a) * a + c. a is the subtrahend and stays on X: MULT_ADD_C
module dspv4_xpath_refused (
    input clk,
    input signed [15:0] sub_d, input signed [15:0] sub_a, output signed [33:0] sub_p,
    input signed [15:0] alu_d, input signed [15:0] alu_a,
    input signed [31:0] alu_c, output signed [34:0] alu_p,
    input signed [15:0] acc_d, input signed [15:0] acc_a, output reg signed [49:0] acc_p,
    input signed [15:0] subc_d, input signed [15:0] subc_a,
    input signed [31:0] subc_c, output signed [34:0] subc_p
);
  assign sub_p = (sub_d - sub_a) * sub_a;
  assign alu_p = (alu_d + alu_a) * alu_a + alu_c;
  always @(posedge clk) begin
    acc_p <= acc_p + (acc_d + acc_a) * acc_a;
  end
  assign subc_p = (subc_d - subc_a) * subc_a + subc_c;
endmodule
