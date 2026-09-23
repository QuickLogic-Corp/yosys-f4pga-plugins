// Pre-adder feeding the accumulator. Phase 4, M1.
//
// The pre-adder fold and the accumulator fold have to survive together: the
// sum goes into the DSP and the product accumulates into P, with nothing
// left in fabric.
module dspv4_preadd_a_macc (input CLK,
                            input signed [15:0] D, input signed [15:0] A,
                            input signed [17:0] B,
                            output reg signed [49:0] P);
  always @(posedge CLK) P <= P + (D + A) * B;
endmodule
