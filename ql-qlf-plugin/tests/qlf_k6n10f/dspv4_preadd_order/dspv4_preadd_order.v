// Reversed operand order. Phase 4, M1.
//
// Subtract is not commutative, so (A - D) * B cannot be folded by swapping
// the operands -- that would compute (D - A) * B. It folds anyway, because
// the pass puts whichever operand needs the dedicated D PORT on it. "D" in a
// mode name is a port, not a signal name.
module dspv4_preadd_order (input signed [15:0] D, input signed [15:0] A,
                           input signed [17:0] B,
                           output signed [34:0] P);
  assign P = (A - D) * B;
endmodule
