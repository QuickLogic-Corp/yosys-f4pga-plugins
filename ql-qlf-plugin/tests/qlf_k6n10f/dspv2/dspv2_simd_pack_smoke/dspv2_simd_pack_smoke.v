// Smoke: SIMD pair-pack of two 16x9 MACs into one fractured cell.
//
// Two independent signed 16x9 multiply-accumulators share the same
// clock/reset/enable. ql_dsp_macc -dspv2 infers each MAC into its own
// dspv2_16x9x32_cfg_ports cell; ql_dsp_simd -dspv2 then packs both
// halves into a single dspv2_32x18x64_cfg_ports cell with FRAC_MODE=1;
// dspv2_final_map collapses that into a single QL_DSPV2 wrapper which
// ql_dspv2_types splits into one typed wrapper.
//
// Plain RTL only -- no DSPv2-specific helpers -- so the W1.6 equiv
// harness has a clean behavioural reference. Module name matches the
// test directory name so DESIGN_TOP wiring is correct.
module dspv2_simd_pack_smoke (
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
