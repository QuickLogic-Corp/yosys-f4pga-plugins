// _ring2 of dspv4_casc_loop_no_register. Keep s1 on line 8, s2 on line 9: the
// cell met first gets the first name, so s1 keeps its C.
module _ring2 (
    input  signed [31:0] a1, a2,
    input  signed [17:0] b1, b2,
    output signed [49:0] s1, s2
);
    assign s1 = a1 * b1 + s2;
    assign s2 = a2 * b2 + s1;
endmodule
