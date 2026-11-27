// One adder feeding both multiply operands. That is the squaring shape, which
// needs AMULTSEL and BMULTSEL set together, and belongs to the squaring phase.
//
// Absorbing it here would rewrite one multiplier port and leave the other
// reading a cell that no longer exists -- every output bit X. Must be refused
// and left in fabric.
//
// The registered block is the same shape with the sum in a register, unsigned
// (aurora2 #2807). Its 18x18 multiply does not fit one DSP. Plugin 89a612e
// offered the adder on one side through the register, deleted the register,
// then read it again for the other operand, and yosys aborted with dict::at().
module dspv4_preadd_square (input signed [15:0] a, input signed [15:0] b,
                            output signed [33:0] y,
                            input clk, input [16:0] registered_d,
                            input [16:0] registered_a,
                            output [35:0] registered_p);
  wire signed [16:0] s = a + b;
  assign y = s * s;

  reg [17:0] registered_sum;
  always @(posedge clk) begin
    registered_sum <= registered_d + registered_a;
  end
  assign registered_p = registered_sum * registered_sum;
endmodule
