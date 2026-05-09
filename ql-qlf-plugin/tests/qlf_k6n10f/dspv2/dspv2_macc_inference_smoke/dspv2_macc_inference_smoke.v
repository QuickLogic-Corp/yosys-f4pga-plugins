// Smoke: signed 16x9 multiply-accumulate inference via ql_dsp_macc -dspv2.
//
// This is a plain MAC pattern (no DSPv2-specific hints, no helper macros)
// so the equiv harness can prove the post-synth netlist matches it as
// behavioural reference. The synth_quicklogic -dspv2 flow is expected to
// infer this into a single dspv2_16x9x32_cfg_ports cell, then collapse it
// into a QL_DSPV2 wrapper, then split it into a typed
// QL_DSPV2_MULTACC_REGOUT (output FF absorbed by W1.1's encoding fix).
//
// Module name matches the test directory name so Makefile_test.common
// drives DESIGN_TOP correctly.
module dspv2_macc_inference_smoke (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    wire signed [24:0] mul = a * b;

    always @(posedge clk) begin
        if (rst)
            z <= 25'sd0;
        else if (en)
            z <= z + mul;
    end
endmodule
