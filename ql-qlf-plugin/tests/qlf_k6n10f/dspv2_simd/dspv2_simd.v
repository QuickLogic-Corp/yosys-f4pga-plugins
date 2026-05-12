// SIMD packing designs for DSPv2 ql_dsp_simd pass testing
// Two independent 16x9 multiplies should be packed into one QL_DSPV2

// Two independent signed 8x8 multiplies - should pack into one QL_DSPV2
// with FRAC_MODE=1
module simd_mult_8x8 (
    input  signed [7:0]  a0,
    input  signed [7:0]  b0,
    output signed [15:0] z0,

    input  signed [7:0]  a1,
    input  signed [7:0]  b1,
    output signed [15:0] z1
);
    assign z0 = a0 * b0;
    assign z1 = a1 * b1;
endmodule

// Two independent signed 16x9 multiplies - should pack into one QL_DSPV2
module simd_mult_16x9 (
    input  signed [15:0] a0,
    input  signed [8:0]  b0,
    output signed [24:0] z0,

    input  signed [15:0] a1,
    input  signed [8:0]  b1,
    output signed [24:0] z1
);
    assign z0 = a0 * b0;
    assign z1 = a1 * b1;
endmodule

// Three independent 8x8 multiplies - should produce 2 QL_DSPV2
// (two packed as SIMD, one standalone)
module simd_mult_three (
    input  signed [7:0]  a0, a1, a2,
    input  signed [7:0]  b0, b1, b2,
    output signed [15:0] z0, z1, z2
);
    assign z0 = a0 * b0;
    assign z1 = a1 * b1;
    assign z2 = a2 * b2;
endmodule
