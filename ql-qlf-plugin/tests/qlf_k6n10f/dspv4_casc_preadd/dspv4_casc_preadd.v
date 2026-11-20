// dspv4_casc_preadd -- pre-adder stages, (d + a) * b + prev, whose link is
// made, at -chain_max 12. One module per block; dspv4_casc_preadd.tcl runs
// each on its own.

// A MULT_ADD_C head, then three pre-adder stages, each reading the whole sum
// above it. Each sum is one bit wider than the P range it holds needs.
module _preadd (
    input  signed [17:0] a0, b0, c0, d1, a1, b1, d2, a2, b2, d3, a3, b3,
    output signed [39:0] s3_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] s1 = (d1 + a1) * b1 + prev;
    wire signed [38:0] s2 = (d2 + a2) * b2 + s1;
    wire signed [39:0] s3 = (d3 + a3) * b3 + s2;
    assign s3_out = s3;
endmodule

// Three pre-adder stages. The head adds c0, so its own $mul takes an $add.
// The bound is on the link out of the second stage: its range holds two
// pre-adder products, and s2 has the 39 bits that needs.
module _preadd_38 (
    input  signed [17:0] d0, a0, b0, c0, d1, a1, b1, d2, a2, b2,
    output signed [39:0] s3_out
);
    wire signed [37:0] s1 = (d0 + a0) * b0 + c0;
    wire signed [38:0] s2 = (d1 + a1) * b1 + s1;
    wire signed [39:0] s3 = (d2 + a2) * b2 + s2;
    assign s3_out = s3;
endmodule

// A pre-adder stage whose result a fabric $add reads: (d1 + a1) * b1 + prev,
// then + k. The pre-adder cell links, and the $add stays.
module _preadd_addend_g1 (
    input  signed [17:0] a0, b0, c0, d1, a1, b1, k,
    output signed [38:0] y_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] s = (d1 + a1) * b1 + prev;
    wire signed [38:0] y = s + k;
    assign y_out = y;
endmodule

// The same with a MULT_ADD_C stage below, which takes the $add's sum on C.
// That stage folds the $add, from its side.
module _preadd_addend_mixed (
    input  signed [17:0] a0, b0, c0, d1, a1, b1, k, a2, b2,
    output signed [40:0] z_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] s = (d1 + a1) * b1 + prev;
    wire signed [38:0] y = s + k;
    wire signed [40:0] z = a2 * b2 + y;
    assign z_out = z;
endmodule
