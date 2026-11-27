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

// A pre-subtract stage, (d1 - a1) * b1 + s1, after a plain MULT_ADD_C head.
// There is no pre-subtract cascade word, so its C stays: no link.
module _preadd_sub_c (
    input  signed [17:0] a0, b0, c0, d1, a1, b1,
    output signed [38:0] s2_out
);
    wire signed [37:0] s1 = a0 * b0 + c0;
    wire signed [38:0] s2 = (d1 - a1) * b1 + s1;
    assign s2_out = s2;
endmodule

// The same pre-subtract stage, s3, below two pre-adder stages. The link into
// s2 is made; the link into s3 is not.
module _preadd_sub_c_after_link (
    input  signed [17:0] d0, a0, b0, c0, d1, a1, b1, d2, a2, b2,
    output signed [39:0] s3_out
);
    wire signed [37:0] s1 = (d0 + a0) * b0 + c0;
    wire signed [38:0] s2 = (d1 + a1) * b1 + s1;
    wire signed [39:0] s3 = (d2 - a2) * b2 + s2;
    assign s3_out = s3;
endmodule
