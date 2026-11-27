// _loop_no_register of dspv4_casc_pcin17_loop. Keep s1 on line 8, s2 on 9:
// the cell met first gets the first name, so s1 keeps its C (see _loop).
module _loop_no_register (
    input  signed [31:0] a1, a2,
    input  signed [17:0] b1, b2,
    output signed [49:0] s1, s2
);
    assign s1 = a1 * b1 + (s2 >>> 17);
    assign s2 = a2 * b2 + (s1 >>> 17);
endmodule
