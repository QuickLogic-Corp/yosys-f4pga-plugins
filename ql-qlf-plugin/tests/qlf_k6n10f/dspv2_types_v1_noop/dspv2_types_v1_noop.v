// Regression-coverage source for the DSPv1 flow: a plain signed 20x18
// multiplier that should map to QL_DSP2_MULT / QL_DSP3_MULT depending on
// flags. Used by dspv2_types_v1_noop.tcl to verify that the unconditional
// ql_dspv2_types pass leaves DSPv1 netlists untouched.

module mult_20x18_s (
    input  signed [19:0] a,
    input  signed [17:0] b,
    output signed [37:0] z
);
    assign z = a * b;
endmodule
