// _loop3_at_cap of dspv4_casc_pcin17_loop: the _loop3 RTL, run at
// -chain_max 3, in a file of its own for the same reason.
module _loop3_at_cap (
    input clk,
    input  signed [31:0] a1, a2, a3,
    input  signed [17:0] b1, b2, b3,
    output reg signed [49:0] s1,
    output signed [49:0] s2, s3
);
    always @(posedge clk) s1 <= a1 * b1 + (s3 >>> 17);
    assign s2 = a2 * b2 + (s1 >>> 17);
    assign s3 = a3 * b3 + (s2 >>> 17);
endmodule
