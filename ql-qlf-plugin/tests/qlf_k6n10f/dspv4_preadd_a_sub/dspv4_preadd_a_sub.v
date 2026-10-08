// Pre-adder subtract on the A path. Phase 4, M1.
//
// D and A are 16 bits, so the sum needs 17 and sits inside AD on the A path.
// B at 18 bits is the other multiplier port.
module dspv4_preadd_a_sub (input signed [15:0] D, input signed [15:0] A,
                           input signed [17:0] B,
                           output signed [34:0] P);
  assign P = (D - A) * B;
endmodule
