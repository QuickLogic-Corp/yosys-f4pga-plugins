// Z-cascade and post-adder designs for DSPv2 ql_dsp_dspv2 cascade pass testing

// Basic cascade: z = (a1 * b1) + (a2 * b2)
// Should produce 2 QL_DSPV2 cells connected via z_cout_o/z_cin_i
module cascade_add (
    input  signed [19:0] a1, a2,
    input  signed [17:0] b1, b2,
    output signed [38:0] z
);
    assign z = (a1 * b1) + (a2 * b2);
endmodule

// Cascade with subtraction: z = (a1 * b1) - (a2 * b2)
module cascade_sub (
    input  signed [19:0] a1, a2,
    input  signed [17:0] b1, b2,
    output signed [38:0] z
);
    assign z = (a1 * b1) - (a2 * b2);
endmodule

// No cascade: two independent multiplies (no adder connecting them)
module no_cascade_independent (
    input  signed [19:0] a1, a2,
    input  signed [17:0] b1, b2,
    output signed [37:0] z1, z2
);
    assign z1 = a1 * b1;
    assign z2 = a2 * b2;
endmodule
