// dspv4_casc_preadd_refused -- pre-adder stages whose link is refused, or
// that have no link to make. One module per block;
// dspv4_casc_preadd_refused.tcl runs each on its own.

// As _preadd_38 in dspv4_casc_preadd, with s2 one bit short of the range of
// two pre-adder products. s3 keeps more bits than it reads of s2.
module _preadd_37 (
    input  signed [17:0] d0, a0, b0, c0, d1, a1, b1, d2, a2, b2,
    output signed [39:0] s3_out
);
    wire signed [37:0] s1 = (d0 + a0) * b0 + c0;
    wire signed [37:0] s2 = (d1 + a1) * b1 + s1;
    wire signed [39:0] s3 = (d2 + a2) * b2 + s2;
    assign s3_out = s3;
endmodule

// A pre-adder stage whose C is the sum of a fabric $add, prev + k: the C is
// not another cell's result, so there is no link.
module _preadd_addend_g2 (
    input  signed [17:0] a0, b0, c0, d1, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = (d1 + a1) * b1 + t;
    assign s_out = s;
endmodule
