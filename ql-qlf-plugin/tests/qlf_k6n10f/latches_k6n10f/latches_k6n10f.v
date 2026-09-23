module my_latch (
    input  wire d, g,
    output reg  q
);
    always @(*)
        if (g) q <= d;
endmodule

module my_latchn (
    input  wire d, g,
    output reg  q
);
    always @(*)
        if (!g) q <= d;
endmodule
