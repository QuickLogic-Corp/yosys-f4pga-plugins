// dspv4_chain_report -- chains the flow makes, which the chain length line
// counts. One module per block; dspv4_chain_report.tcl runs each on its own.

// One multiply, no link.
module _none (
    input  signed [17:0] a, b,
    output signed [35:0] p
);
    assign p = a * b;
endmodule

// Two stages, one link.
module _two (
    input  signed [17:0] a, b, c, d,
    output signed [49:0] result
);
    wire signed [35:0] p = a * b;
    assign result = p + c * d;
endmodule

// mul2dsp splits b into b[16:0] and b[18:17]. The upper piece reads the lower
// piece through PCIN >> 17: two cells in one column.
module _pcin17 (
    input  signed [31:0] a,
    input  signed [18:0] b,
    output signed [50:0] p
);
    assign p = a * b;
endmodule

// x reads p0 through PCIN >> 17 and y reads x through PCIN: one column of three.
module _mixed_at_cap (
    input  signed [31:0] a0, a1, a2,
    input  signed [17:0] b0, b1, b2,
    output signed [49:0] p0, x, y
);
    assign p0 = a0 * b0;
    assign x  = a1 * b1 + (p0 >>> 17);
    assign y  = a2 * b2 + x;
endmodule

// x and z both read p0 >>> 17; x heads a plain link to y. At -chain_max 2,
// z takes p0's PCOUT and x reads p0 on C: two columns of two.
module _two_readers (
    input  signed [31:0] a0, a1, a2, a3,
    input  signed [17:0] b0, b1, b2, b3,
    output signed [49:0] p0, x, y, z
);
    assign p0 = a0 * b0;
    assign x  = a1 * b1 + (p0 >>> 17);
    assign z  = a3 * b3 + (p0 >>> 17);
    assign y  = a2 * b2 + x;
endmodule

// The _two_readers RTL at -chain_max 3: x takes p0's PCOUT, one column of three.
module _two_readers_at_cap (
    input  signed [31:0] a0, a1, a2, a3,
    input  signed [17:0] b0, b1, b2, b3,
    output signed [49:0] p0, x, y, z
);
    assign p0 = a0 * b0;
    assign x  = a1 * b1 + (p0 >>> 17);
    assign z  = a3 * b3 + (p0 >>> 17);
    assign y  = a2 * b2 + x;
endmodule
