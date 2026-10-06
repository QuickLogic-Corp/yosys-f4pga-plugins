// Pre-adder feeding the accumulator. Phase 4, M1.
//
// The pre-adder fold and the accumulator fold have to survive together: the
// sum goes into the DSP and the product accumulates into P, with nothing
// left in fabric.
//
// The +P+C blocks need the feedback on the FIRST adder and C on the second:
// `(m + P) + C`, not `P + (m + C)`. classify() measures the feedback against
// alu_addend only, so the other order never reaches MULT_ACC_C and the mode
// looks unreachable.
module dspv4_preadd_a_macc (input CLK,
                            input signed [15:0] D, input signed [15:0] A,
                            input signed [17:0] B,
                            output reg signed [49:0] P,
                            // PREADD_A_MACC_C -- the A path with a C term
                            input signed [15:0] cd, input signed [15:0] ca,
                            input signed [17:0] cb, input signed [35:0] cc,
                            output reg signed [49:0] cp,
                            // PREADD_B_MACC_C -- cb is 32 bits, forcing the B path
                            input signed [15:0] ed, input signed [15:0] ea,
                            input signed [31:0] eb, input signed [35:0] ec,
                            output reg signed [49:0] ep);
  always @(posedge CLK) P <= P + (D + A) * B;
  always @(posedge CLK) cp <= ((cd + ca) * cb + cp) + cc;
  always @(posedge CLK) ep <= ((ed + ea) * eb + ep) + ec;
endmodule
