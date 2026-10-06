// Pre-adder subtract with a fused back-end. The mode table wrote these modes
// as "(D +/- A) * B + ..." -- one row for both directions -- and listed only
// the add control word, so the subtract direction was refused for want of one.
//
// Four blocks: the +C and +P back-ends, each on the A path and the B path.
// The A path keeps all 32 bits of AD. The B path truncates it to 18 and is
// forced here by giving the other multiply operand 32 bits, so it cannot sit
// on the 18-bit B port.
//
// adder_carry 0 is the assertion with teeth. The pre-subtract and the fused
// addend are both additions, and the arithmetic is right whether or not either
// one folded -- only a surviving carry chain shows it did not.
//
// The +P+C blocks need the feedback on the FIRST adder and C on the second:
// `(m + p) + c`, not `p + (m + c)`. classify() measures the feedback against
// alu_addend only, so the other order classifies as MULT_ADD_C and never
// reaches MULT_ACC_C.
module dspv4_preadd_sub_fused (
    input clk,
    // (D - A) * B + C
    input signed [14:0] d0, input signed [14:0] a0, input signed [14:0] b0,
    input signed [33:0] c0, output signed [33:0] p0,
    input signed [14:0] d1, input signed [14:0] a1, input signed [31:0] b1,
    input signed [49:0] c1, output signed [49:0] p1,
    // (D - A) * B + P
    input signed [14:0] d2, input signed [14:0] a2, input signed [14:0] b2,
    output reg signed [49:0] p2,
    input signed [14:0] d3, input signed [14:0] a3, input signed [31:0] b3,
    output reg signed [49:0] p3,
    // (D - A) * B + P + C
    input signed [14:0] d4, input signed [14:0] a4, input signed [17:0] b4,
    input signed [35:0] c4, output reg signed [49:0] p4,
    input signed [14:0] d5, input signed [14:0] a5, input signed [31:0] b5,
    input signed [35:0] c5, output reg signed [49:0] p5
);
  assign p0 = c0 + (d0 - a0) * b0;
  assign p1 = c1 + (d1 - a1) * b1;

  always @(posedge clk) p2 <= p2 + (d2 - a2) * b2;
  always @(posedge clk) p3 <= p3 + (d3 - a3) * b3;

  always @(posedge clk) p4 <= ((d4 - a4) * b4 + p4) + c4;
  always @(posedge clk) p5 <= ((d5 - a5) * b5 + p5) + c5;
endmodule
