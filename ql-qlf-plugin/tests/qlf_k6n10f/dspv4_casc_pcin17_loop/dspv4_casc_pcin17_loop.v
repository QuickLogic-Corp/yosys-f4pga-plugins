// _loop of dspv4_casc_pcin17_loop. Keep s2 on line 9 and s1 on line 10: the
// matcher meets cells in the text order of their names, which hold the line,
// so it meets s1 first and s1 keeps its register in P.
module _loop (
    input clk,
    input  signed [31:0] a1, a2,
    input  signed [17:0] b1, b2,
    output reg signed [49:0] s1, output signed [49:0] s2);
    assign s2 = a2 * b2 + (s1 >>> 17);
    always @(posedge clk) s1 <= a1 * b1 + (s2 >>> 17);
endmodule
