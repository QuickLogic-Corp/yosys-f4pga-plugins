// Smoke: SIMD pair-pack of two 16x9 MACs into one fractured 32x18x64 cell.
// Two independent signed 16x9 multiply-accumulators share the same
// clock/reset/control. ql_dsp_macc -dspv2 infers each as a
// dspv2_16x9x32_cfg_ports cell; ql_dsp_simd -dspv2 then packs both into a
// single dspv2_32x18x64_cfg_ports cell with FRAC_MODE=1.
module top (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire signed [15:0]    a0,
    input  wire signed  [8:0]    b0,
    input  wire signed [15:0]    a1,
    input  wire signed  [8:0]    b1,
    output reg  signed [24:0]    z0,
    output reg  signed [24:0]    z1
);
    wire signed [24:0] mul0 = a0 * b0;
    wire signed [24:0] mul1 = a1 * b1;

    always @(posedge clk) begin
        if (rst) begin
            z0 <= 25'sd0;
            z1 <= 25'sd0;
        end else if (en) begin
            z0 <= z0 + mul0;
            z1 <= z1 + mul1;
        end
    end
endmodule
