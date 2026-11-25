// The dspv4_casc_pcin17 multiply, synthesised with -no_pcin17.
module _pcin17_off (
    input  signed [31:0] a,
    input  signed [18:0] b,
    output signed [50:0] p
);
    assign p = a * b;
endmodule

// p1 reads p0 on PCIN, so p1 cannot also be the source of p2's PCIN >> 17.
module _mixed (
    input  signed [31:0] a0, a1, a2,
    input  signed [17:0] b0, b1, b2,
    output signed [49:0] p0, p1, p2
);
    assign p0 = a0 * b0;
    assign p1 = a1 * b1 + p0;
    assign p2 = a2 * b2 + (p1 >>> 17);
endmodule

// x reads p0 through PCIN >> 17 and y reads x through PCIN: one column of three.
module _mixed_cap (
    input  signed [31:0] a0, a1, a2,
    input  signed [17:0] b0, b1, b2,
    output signed [49:0] p0, x, y
);
    assign p0 = a0 * b0;
    assign x  = a1 * b1 + (p0 >>> 17);
    assign y  = a2 * b2 + x;
endmodule
