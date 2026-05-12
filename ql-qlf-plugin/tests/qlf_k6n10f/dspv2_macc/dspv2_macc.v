// Multiply-accumulate designs for DSPv2 MACC inference

// Basic MAC: z += a * b
module macc_32x18 (
    input             clk,
    input             rst,
    input  signed [31:0] a,
    input  signed [17:0] b,
    output reg signed [63:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else
            z <= z + a * b;
endmodule

// 16x9 MAC (fractured)
module macc_16x9 (
    input             clk,
    input             rst,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [31:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else
            z <= z + a * b;
endmodule
