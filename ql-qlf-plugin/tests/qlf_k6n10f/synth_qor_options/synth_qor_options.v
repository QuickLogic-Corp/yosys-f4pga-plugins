// One small module per QoR option of synth_ql (-small_mul_width, -carry_min_width,
// -cmp2lut_width, -keep_syn_preserve).

// Constant multiply with wide operands (8 and 5 bits): stays on the DSP with
// -small_mul_width 4.
module mul_c (
    input clk,
    input [7:0] a,
    output reg [15:0] m
);
  always @(posedge clk) m <= a * 8'd25;
endmodule

// Narrow select times a constant (an index offset): logic with -small_mul_width 2.
module mul_sel (
    input clk,
    input [1:0] s,
    output reg [7:0] m
);
  always @(posedge clk) m <= s * 8'd24;
endmodule

// 9-bit adder: adder_carry by default, LUTs with -carry_min_width above 9.
module add9 (
    input  [7:0] a,
    input  [7:0] b,
    output [8:0] s
);
  assign s = a + b;
endmodule

// 6-bit compare with a constant: one LUT by default on qlf_k6n10f (LUT size 6),
// carry logic with -cmp2lut_width 4.
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
