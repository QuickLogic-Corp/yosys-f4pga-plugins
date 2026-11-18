// dspv4_casc_refused -- reads of another DSP's result that must not become a
// PCIN link. One module per block; dspv4_casc_refused.tcl runs each on its own.

// An unsigned sum. The second stage reads it zero-extended, and PCIN would
// sign-extend it.
module _unsigned (
    input  [16:0] a0, b0, a1, b1, c0,
    output [37:0] y
);
    wire [36:0] s1 = a0 * b0 + c0;
    assign y = a1 * b1 + s1;
endmodule

// A signed sum read through a zero pad. s2 is wider than s1, so the pad
// survives to the adder.
module _pad (
    input  signed [17:0] a0, b0, a1, b1,
    output signed [37:0] s2_out
);
    wire signed [35:0] s1 = a0 * b0;
    wire signed [37:0] s2 = a1 * b1 + $signed({1'b0, s1});
    assign s2_out = s2;
endmodule

// A shifted read: bit 0 of the second stage's addend is bit 5 of the first
// stage's result.
module _slice (
    input  signed [17:0] a0, b0, a1, b1, c0,
    output signed [36:0] s_out
);
    wire signed [35:0] prev = a0 * b0 + c0;
    wire signed [36:0] s = a1 * b1 + (prev >>> 5);
    assign s_out = s;
endmodule

// An addend built from two results: one product in the low 36 bits, 14 bits of
// another above it.
module _multicell (
    input  signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [49:0] s_out
);
    wire signed [35:0] p0 = a0 * b0;
    wire signed [35:0] p1 = a1 * b1;
    wire signed [49:0] s = a2 * b2 + $signed({p1[13:0], p0});
    assign s_out = s;
endmodule

// A stage that subtracts. There is no PCIN mode for it.
module _sub (
    input  signed [17:0] a0, b0, a1, b1, c0,
    output signed [37:0] y
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y = prev - a1 * b1;
endmodule

// A stage that accumulates as well as adding the previous result. There is no
// PCIN mode for it.
module _acc_tail (
    input                    clk, rst,
    input      signed [17:0] a0, b0, a1, b1, c0,
    output reg signed [49:0] p
);
    wire signed [36:0] prev = a0 * b0 + c0;
    always @(posedge clk)
        if (rst) p <= 0;
        else     p <= p + a1 * b1 + prev;
endmodule

// A pre-adder stage on the B path: a is too wide for the B port, so the sum
// d + b goes there. There is no PCIN mode for it.
module _preadd_b (
    input  signed [17:0] a0, b0, c0,
    input  signed [19:0] a,
    input  signed [16:0] d, b,
    output signed [38:0] y
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y = (d + b) * a + prev;
endmodule
