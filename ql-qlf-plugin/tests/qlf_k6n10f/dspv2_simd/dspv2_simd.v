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

// SIMD-packing negative case: two 16x9 MACs driven by different clocks have
// non-matching control-port connections (R-SIMD-1). ql_dsp_simd -dspv2 must
// leave them as two separate dspv2_16x9x32_cfg_ports cells (-> 2 QL_DSPV2_MULTACC).
module simd_mismatched_clk (
    input              clk0,
    input              clk1,
    input              rst,
    input  signed [15:0] a0, a1,
    input  signed [8:0]  b0, b1,
    output reg signed [31:0] z0, z1
);
    always @(posedge clk0)
        if (rst) z0 <= 0; else z0 <= z0 + a0 * b0;
    always @(posedge clk1)
        if (rst) z1 <= 0; else z1 <= z1 + a1 * b1;
endmodule

// SIMD-packing negative case: a wire on one product is marked (* keep *),
// which R-SIMD-3c says blocks packing of that pair. Result: 2 standalone
// 16x9 cells (-> 2 QL_DSPV2_MULT after ql_dspv2_types).
module simd_mult_keep_attr (
    input  signed [15:0] a0, a1,
    input  signed [8:0]  b0, b1,
    output signed [24:0] z0,
    output signed [24:0] z1
);
    (* keep *) wire signed [24:0] z0_kept;
    assign z0_kept = a0 * b0;
    assign z0 = z0_kept;
    assign z1 = a1 * b1;
endmodule
