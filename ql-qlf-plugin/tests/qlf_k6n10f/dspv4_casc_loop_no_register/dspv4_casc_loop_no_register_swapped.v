// _ring2_swapped of dspv4_casc_loop_no_register: _ring2 with the lines
// exchanged. The cell met first is now s2's, so s2 keeps its C.
module _ring2_swapped (
    input  signed [31:0] a1, a2,
    input  signed [17:0] b1, b2,
    output signed [49:0] s1, s2
);
    assign s2 = a2 * b2 + s1;
    assign s1 = a1 * b1 + s2;
endmodule
