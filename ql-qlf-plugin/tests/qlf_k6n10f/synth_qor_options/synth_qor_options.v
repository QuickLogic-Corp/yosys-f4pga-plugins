// One small module per QoR option of synth_ql (-mcm, -carry_min_width,
// -cmp2lut_width, -keep_syn_preserve).

// Constant multiply: a DSP by default, shifts and adds with -mcm.
module mul_c (
    input clk,
    input [7:0] a,
    output reg [15:0] m
);
  always @(posedge clk) m <= a * 8'd25;
endmodule

// 9-bit adder: adder_carry by default, LUTs with -carry_min_width above 9.
module add9 (
    input  [7:0] a,
    input  [7:0] b,
    output [8:0] s
);
  assign s = a + b;
endmodule

// 6-bit compare with a constant: carry logic by default (cmp2lut width 4),
// a LUT with -cmp2lut_width 6.
module cmp6 (
    input  [5:0] c,
    output       lt
);
  assign lt = c < 6'd37;
endmodule

// Two copies of one register, kept apart for fanout: merged by default,
// kept with -keep_syn_preserve.
module dup_ff (
    input clk,
    input d,
    output reg q1,
    output reg q2
);
  (* syn_preserve = 1 *) reg r1;
  (* syn_preserve = 1 *) reg r2;
  always @(posedge clk) begin
    r1 <= d;
    r2 <= d;
    q1 <= r1;
    q2 <= r2;
  end
endmodule
