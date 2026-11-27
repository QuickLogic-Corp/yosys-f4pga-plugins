// mul2dsp splits b into b[16:0] and b[18:17]. The upper piece adds the lower
// piece's product shifted right by 17: the shape PCIN >> 17 carries.
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

// x and z both read p0 >>> 17; x heads a plain link to y.
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

// The _two_readers RTL at -chain_max 3.
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

// x and z both read p0 >>> 17; z heads a plain link to y, so z has the longer
// chain below it. x comes first in the RTL.
module _longer_chain_later (
    input  signed [31:0] a0, a1, a2, a3,
    input  signed [17:0] b0, b1, b2, b3,
    output signed [49:0] p0, x, y, z
);
    assign p0 = a0 * b0;
    assign x  = a1 * b1 + (p0 >>> 17);
    assign z  = a3 * b3 + (p0 >>> 17);
    assign y  = a2 * b2 + z;
endmodule

// x and z both read p0 >>> 17, and neither heads a chain.
module _equal_chains (
    input  signed [31:0] a0, a1, a3,
    input  signed [17:0] b0, b1, b3,
    output signed [49:0] p0, x, z
);
    assign p0 = a0 * b0;
    assign x  = a1 * b1 + (p0 >>> 17);
    assign z  = a3 * b3 + (p0 >>> 17);
endmodule
