// dspv4_casc_links -- chains the pass links, and one it must leave alone.
// One module per block; dspv4_casc_links.tcl runs each on its own.

// A two-stage chain written by hand, in the shape the pass itself would make:
// the second cell is MULT_ADD_C and its C is the first cell's P, sign-extended
// from 36 bits. The pass did not make these cells, so it must not link them.
module _macro (
    input  signed [17:0] a0, b0, a1, b1,
    output signed [36:0] y
);
    wire [49:0] head_p;
    wire [49:0] tail_p;
    assign y = tail_p[36:0];

    QL_DSP4 #(
        .OPMODE(9'b000000101)
    ) head (
        .A({{14{a0[17]}}, a0}),
        .B(b0),
        .CIN(1'b0),
        .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
        .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1),
        .P(head_p)
    );

    QL_DSP4 #(
        .OPMODE(9'b000110101)
    ) tail (
        .A({{14{a1[17]}}, a1}),
        .B(b1),
        .C({{14{head_p[35]}}, head_p[35:0]}),
        .CIN(1'b0),
        .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
        .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1),
        .P(tail_p)
    );
endmodule

// Five stages. Each sum is as wide as the range of the wires added so far
// needs: 36, 37, 38, 38 and 39 bits.
module _chain (
    input  signed [17:0] a1, b1, a2, b2, a3, b3, a4, b4, a5, b5,
    output signed [38:0] p_out
);
    wire signed [35:0] s1 = a1 * b1;
    wire signed [36:0] s2 = (a2 * b2) + s1;
    wire signed [37:0] s3 = (a3 * b3) + s2;
    wire signed [37:0] s4 = (a4 * b4) + s3;
    wire signed [38:0] s5 = (a5 * b5) + s4;
    assign p_out = s5;
endmodule

// Two stages: a bare product, then a multiply that adds it.
module _two (
    input  signed [17:0] a0, b0, a1, b1,
    output signed [36:0] s_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// Three 32 x 18 stages, every sum 50 bits. By the formula the head's range
// already needs 51 bits; the 50-bit port is the ceiling.
module _wide_chain (
    input  signed [31:0] a0, a1, a2,
    input  signed [17:0] b0, b1, b2, c0,
    output signed [49:0] s2_out
);
    wire signed [49:0] prev = a0 * b0 + c0;
    wire signed [49:0] s1 = a1 * b1 + prev;
    wire signed [49:0] s2 = a2 * b2 + s1;
    assign s2_out = s2;
endmodule

// Three stages. The tail keeps 36 bits and reads 36 bits of a 37-bit sum.
module _trunc (
    input  signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [36:0] s0_out,
    output signed [35:0] s1_out
);
    wire signed [35:0] p0 = a0 * b0;
    wire signed [36:0] s0 = a1 * b1 + p0;
    assign s0_out = s0;
    wire signed [35:0] s1 = a2 * b2 + s0;
    assign s1_out = s1;
endmodule
