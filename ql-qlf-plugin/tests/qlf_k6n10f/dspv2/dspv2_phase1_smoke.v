// Phase-1 smoke test for Yosys-driven DSPv2 inference.
//
// A single signed 32×18 multiply must lower through:
//   $mul → $__MUL32X18 → dspv2_32x18x64_cfg_ports → QL_DSPV2 → QL_DSPV2_MULT
module dspv2_phase1_smoke (
    input  wire signed [31:0] a,
    input  wire signed [17:0] b,
    output wire signed [49:0] y
);
    assign y = a * b;
endmodule
