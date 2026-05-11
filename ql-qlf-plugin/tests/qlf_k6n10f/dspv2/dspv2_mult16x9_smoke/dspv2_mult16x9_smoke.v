// Smoke: $mul → QL_DSPV2_MULT lowering chain for 16×9 operands.
//
// A single signed 16×9 multiply must lower through:
//   $mul → $__MUL16X9 → dspv2_16x9x32_cfg_ports → QL_DSPV2 → QL_DSPV2_MULT
//
// Complements dspv2_mult_lowering_smoke (which tests the 32×18 path).
module dspv2_mult16x9_smoke (
    input  wire signed [15:0] a,
    input  wire signed  [8:0] b,
    output wire signed [24:0] y
);
    assign y = a * b;
endmodule
