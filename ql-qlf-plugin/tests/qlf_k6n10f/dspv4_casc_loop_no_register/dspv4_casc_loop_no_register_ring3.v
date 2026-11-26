// _ring3 of dspv4_casc_loop_no_register: s1 -> s2 -> s3 -> s1, no register.
module _ring3 (
    input  signed [31:0] a1, a2, a3,
    input  signed [17:0] b1, b2, b3,
    output signed [49:0] s1, s2, s3
);
    assign s1 = a1 * b1 + s3;
    assign s2 = a2 * b2 + s1;
    assign s3 = a3 * b3 + s2;
endmodule
