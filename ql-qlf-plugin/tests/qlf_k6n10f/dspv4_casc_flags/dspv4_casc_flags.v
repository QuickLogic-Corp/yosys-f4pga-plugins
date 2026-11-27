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

// One result read by two stages, for two runs that must give one netlist.
module fanout_det (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, c0,
    output signed [37:0] y1, y2
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y1 = a1 * b1 + prev;
    assign y2 = a2 * b2 + prev;
endmodule

// Five stages and nine stages, each sum as wide as its range needs, for a
// limit of four cells per chain.
module chain5 (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3, a4, b4, c0,
    output signed [38:0] y
);
    wire signed [36:0] s0 = a0 * b0 + c0;
    wire signed [37:0] s1 = a1 * b1 + s0;
    wire signed [37:0] s2 = a2 * b2 + s1;
    wire signed [38:0] s3 = a3 * b3 + s2;
    assign y = a4 * b4 + s3;
endmodule

module chain9 (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3, a4, b4, a5, b5, a6, b6, a7, b7, a8, b8, c0,
    output signed [39:0] y
);
    wire signed [36:0] s0 = a0 * b0 + c0;
    wire signed [37:0] s1 = a1 * b1 + s0;
    wire signed [37:0] s2 = a2 * b2 + s1;
    wire signed [38:0] s3 = a3 * b3 + s2;
    wire signed [38:0] s4 = a4 * b4 + s3;
    wire signed [38:0] s5 = a5 * b5 + s4;
    wire signed [38:0] s6 = a6 * b6 + s5;
    wire signed [39:0] s7 = a7 * b7 + s6;
    assign y = a8 * b8 + s7;
endmodule

// Grouping 1, (a*b + prev) + k, for two pass calls in a row. In declined_a the
// sum s is one bit short of two products, so the fold of the $add is declined;
// in declined_b it is wide enough.
module declined_a (
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [37:0] y
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [35:0] s = a1 * b1 + prev;
    assign y = s + k;
endmodule

module declined_b (
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [37:0] y
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    assign y = s + k;
endmodule
