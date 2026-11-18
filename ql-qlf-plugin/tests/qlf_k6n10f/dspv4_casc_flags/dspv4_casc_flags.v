// dspv4_casc_flags -- what -chain_max does to a chain, per value of N.
// One module per chain shape; dspv4_casc_flags.tcl says which N each block runs.

// Four stages. Each sum is wide enough for the range of the wires added so far:
// 37, 38, 38 and 39 bits.
module chain4 (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    input  signed [17:0] c0,
    output signed [38:0] y
);
    wire signed [36:0] s0 = a0 * b0 + c0;
    wire signed [37:0] s1 = a1 * b1 + s0;
    wire signed [37:0] s2 = a2 * b2 + s1;
    assign y = a3 * b3 + s2;
endmodule

// The same chain twice, for two pass calls in a row: each call needs cells of
// its own to work on.
module chain_a (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    input  signed [17:0] c0,
    output signed [38:0] y
);
    wire signed [36:0] s0 = a0 * b0 + c0;
    wire signed [37:0] s1 = a1 * b1 + s0;
    wire signed [37:0] s2 = a2 * b2 + s1;
    assign y = a3 * b3 + s2;
endmodule

module chain_b (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    input  signed [17:0] c0,
    output signed [38:0] y
);
    wire signed [36:0] s0 = a0 * b0 + c0;
    wire signed [37:0] s1 = a1 * b1 + s0;
    wire signed [37:0] s2 = a2 * b2 + s1;
    assign y = a3 * b3 + s2;
endmodule
