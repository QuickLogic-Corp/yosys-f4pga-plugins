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
