// Two accumulators over one product are one register.
//
// opt runs opt_merge before this pass and takes the two $mul down to one, but
// never touches the $add. Its CSE compares the adders' inputs, and each adder
// reads its OWN flop's Q: the adders are equal only once the flops are known
// equal, and the flops only once the adders are. So the one product is left
// with two accumulator readers, the fan-out guards refuse both -- correctly,
// because an accumulator cannot be copied the way an operand register can, its
// value being its own history -- and both adders and all three registers land
// in fabric.
//
// The two loops are otherwise identical: same clock, same synchronous reset,
// same reset value, same next state. merge_accumulators() in ql-dspv4.cc folds
// them together by induction before the matcher runs.
//
// p1 is the accumulator itself and p2 a register on the other one, so a merge
// that STOLE a loop rather than merging it would strand p1 -- which is what the
// `check -assert` and the two connectivity walks in the .tcl are for. Cell
// counts alone cannot tell a merge from a theft here: both leave one bank.
//
// Reduced from tests/designs/dsp_unit_designs/dsp_multacc_wrap_shared, where
// this shape cost 216 sdffre and 144 adder_carry against Synplify's 72 and none.
module dspv4_macc_dup (input clk, input rst,
                       input signed [17:0] a, input signed [17:0] b,
                       output signed [35:0] p1,
                       output reg signed [35:0] p2);
  reg signed [35:0] acc1, acc2;
  always @(posedge clk) begin
    if (rst) begin acc1 <= 0;               acc2 <= 0;               end
    else     begin acc1 <= acc1 + a * b;    acc2 <= acc2 + a * b;    end
  end
  assign p1 = acc1;
  always @(posedge clk)
    if (rst) p2 <= 0; else p2 <= acc2;
endmodule
