// Basic multiplier designs for DSPv2 inference testing

// 32x18 unsigned multiply - should map to dspv2_32x18x64_cfg_ports then QL_DSPV2
module mult_32x18 (
    input  [31:0] a,
    input  [17:0] b,
    output [49:0] z
);
    assign z = a * b;
endmodule

// 16x9 unsigned multiply - should map to dspv2_16x9x32_cfg_ports then QL_DSPV2 (fractured)
module mult_16x9 (
    input  [15:0] a,
    input  [8:0]  b,
    output [24:0] z
);
    assign z = a * b;
endmodule

// 20x18 signed multiply - should map to dspv2_32x18x64_cfg_ports
module mult_20x18_s (
    input  signed [19:0] a,
    input  signed [17:0] b,
    output signed [37:0] z
);
    assign z = a * b;
endmodule

// 8x8 signed multiply - should map to dspv2_16x9x32_cfg_ports (fractured)
module mult_8x8_s (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output signed [15:0] z
);
    assign z = a * b;
endmodule
