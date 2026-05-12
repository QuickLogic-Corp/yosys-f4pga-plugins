// Register packing designs for DSPv2 ql_dsp_dspv2 pass testing

// Output register packing: the output flop should be absorbed into the DSP
// (output_select_i[2] set to 1)
module mult_output_reg (
    input             clk,
    input  signed [19:0] a,
    input  signed [17:0] b,
    output reg signed [37:0] z
);
    wire signed [37:0] mult;
    assign mult = a * b;
    always @(posedge clk)
        z <= mult;
endmodule

// Input A register packing: the A-input flop should be absorbed into the DSP
// (A_REG set to 1)
module mult_input_a_reg (
    input             clk,
    input  signed [19:0] a,
    input  signed [17:0] b,
    output signed [37:0] z
);
    reg signed [19:0] a_reg;
    always @(posedge clk)
        a_reg <= a;
    assign z = a_reg * b;
endmodule

// Input B register packing: the B-input flop should be absorbed into the DSP
// (B_REG set to 1)
module mult_input_b_reg (
    input             clk,
    input  signed [19:0] a,
    input  signed [17:0] b,
    output signed [37:0] z
);
    reg signed [17:0] b_reg;
    always @(posedge clk)
        b_reg <= b;
    assign z = a * b_reg;
endmodule

// All registers packed: A input reg + B input reg + Z output reg
module mult_all_regs (
    input             clk,
    input  signed [19:0] a,
    input  signed [17:0] b,
    output reg signed [37:0] z
);
    reg signed [19:0] a_reg;
    reg signed [17:0] b_reg;
    always @(posedge clk) begin
        a_reg <= a;
        b_reg <= b;
    end
    wire signed [37:0] mult;
    assign mult = a_reg * b_reg;
    always @(posedge clk)
        z <= mult;
endmodule

// 16x9 fractured variant with output register
module mult_16x9_output_reg (
    input             clk,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [24:0] z
);
    wire signed [24:0] mult;
    assign mult = a * b;
    always @(posedge clk)
        z <= mult;
endmodule
