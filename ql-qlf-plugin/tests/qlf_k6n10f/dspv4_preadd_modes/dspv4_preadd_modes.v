// One shape per pre-adder mode the phase turns on, where the whole thing folds.
//
// Grouped because all five leave nothing in fabric. The shapes that keep a
// carry chain on purpose stay separate: dspv4_preadd_both budgets 12 carries
// for the narrower of its two sums, and a total would let a regression in
// these five hide under that allowance.
//
//   bpath  (d + a) * b with a 32-bit b -> the B port
//   asub   (D - A) * B                 -> PRESUB on the A path
//   bsub   (d - a) * b, 32-bit b       -> PRESUB on the B path
//   order  (A - D) * B, operands the other way round. Subtract does not
//          commute, so the mode name is the evidence nothing was swapped
//   addc   c + (a * (d + b))           -> the fused +C form
module dspv4_preadd_modes (
    input signed [15:0] bpath_d, input signed [15:0] bpath_a,
    input signed [31:0] bpath_b, output signed [48:0] bpath_p,
    input signed [15:0] asub_D, input signed [15:0] asub_A,
    input signed [17:0] asub_B, output signed [34:0] asub_P,
    input signed [15:0] bsub_d, input signed [15:0] bsub_a,
    input signed [31:0] bsub_b, output signed [48:0] bsub_p,
    input signed [15:0] order_D, input signed [15:0] order_A,
    input signed [17:0] order_B, output signed [34:0] order_P,
    input signed [14:0] addc_d, input signed [14:0] addc_a,
    input signed [14:0] addc_b, input signed [33:0] addc_c,
    output signed [33:0] addc_p
);
  assign bpath_p = (bpath_d + bpath_a) * bpath_b;
  assign asub_P  = (asub_D - asub_A) * asub_B;
  assign bsub_p  = (bsub_d - bsub_a) * bsub_b;
  assign order_P = (order_A - order_D) * order_B;
  assign addc_p  = addc_c + (addc_a * (addc_d + addc_b));
endmodule
