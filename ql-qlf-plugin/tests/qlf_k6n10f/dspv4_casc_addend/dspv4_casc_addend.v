// dspv4_casc_addend -- a stage that adds the link and one more value, k, at
// -chain_max 12. One module per block; dspv4_casc_addend.tcl runs each on
// its own.

// Grouping 2, written with brackets: each stage adds (prev + k).
module _addend (
    input  signed [17:0] a0, b0, c0, a1, b1, k1, a2, b2, k2,
    output signed [40:0] s2_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [38:0] s1 = a1 * b1 + (prev + k1);
    wire signed [40:0] s2 = a2 * b2 + (s1 + k2);
    assign s2_out = s2;
endmodule

// Grouping 2 with k written first: the link is the $add's second input.
module _addend_g2_swapped (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = k + prev;
    wire signed [38:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// Grouping 1, written left to right: each stage is (a*b + prev) + k.
module _addend_grouped (
    input  signed [17:0] a0, b0, c0, a1, b1, k1, a2, b2, k2, a3, b3, k3,
    output signed [39:0] y3_out
);
    wire signed [36:0] y0 = a0 * b0 + c0;
    wire signed [37:0] y1 = a1 * b1 + y0 + k1;
    wire signed [38:0] y2 = a2 * b2 + y1 + k2;
    wire signed [39:0] y3 = a3 * b3 + y2 + k3;
    assign y3_out = y3;
endmodule

// Grouping 2 with a registered k. The link itself is not registered.
module _addend_creg (
    input                clk,
    input  signed [17:0] a0, b0, c0, a1, b1, k,
    output signed [38:0] s_out
);
    reg signed [17:0] k_r;
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k_r;
    wire signed [38:0] s = a1 * b1 + t;
    assign s_out = s;
    always @(posedge clk) begin
        k_r <= k;
    end
endmodule

// One $add that is grouping 1 for the cell whose P is a1*b1 + y0, and
// grouping 2 for the a2 cell below it.
module _addend_both (
    input  signed [17:0] a0, b0, a1, b1, k1, a2, b2,
    output signed [38:0] y2
);
    wire signed [35:0] y0 = a0 * b0;
    wire signed [37:0] y1 = a1 * b1 + y0 + k1;
    assign y2 = a2 * b2 + y1;
endmodule

// The same source on PCIN and on C.
module _double_prev (
    input  signed [17:0] a0, b0, a, b,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [37:0] y = a * b + prev + prev;
    assign y_out = y;
endmodule

// The $add reads the consumer's result shifted: not grouping 1.
module _addend_g1_shifted (
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    wire signed [37:0] y = (s >>> 4) + k;
    assign y_out = y;
endmodule

// The $add reads the consumer's result under a zero pad: not grouping 1.
module _addend_g1_in_zero_pad (
    input  signed [17:0] a0, b0, a1, b1,
    input  signed [37:0] k,
    output signed [39:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    wire signed [39:0] y = $signed({1'b0, s}) + k;
    assign y_out = y;
endmodule

// 32 x 18 products, every wire 50 bits: s holds two products, which only
// the 50-bit cap accepts.
module _addend_g1_cap (
    input  signed [31:0] a0, a1,
    input  signed [17:0] b0, b1, k,
    output signed [49:0] y_out
);
    wire signed [49:0] prev = a0 * b0;
    wire signed [49:0] s = a1 * b1 + prev;
    wire signed [49:0] y = s + k;
    assign y_out = y;
endmodule

// Two cells' results on one $add: either could take it.
module _addend_g1_tie (
    input  signed [17:0] a0, b0, c0, a3, b3, c3, a1, b1, a2, b2,
    output signed [38:0] y_out
);
    wire signed [36:0] prev1 = a0 * b0 + c0;
    wire signed [36:0] prev2 = a3 * b3 + c3;
    wire signed [37:0] s1 = a1 * b1 + prev1;
    wire signed [37:0] s2 = a2 * b2 + prev2;
    wire signed [38:0] y = s1 + s2;
    assign y_out = y;
endmodule

// _addend_g1_tie with the two heads' lines and the two consumers' lines
// swapped, so the cells are made in the other order.
module _addend_g1_tie_swapped (
    input  signed [17:0] a0, b0, c0, a3, b3, c3, a1, b1, a2, b2,
    output signed [38:0] y_out
);
    wire signed [36:0] prev2 = a3 * b3 + c3;
    wire signed [36:0] prev1 = a0 * b0 + c0;
    wire signed [37:0] s2 = a2 * b2 + prev2;
    wire signed [37:0] s1 = a1 * b1 + prev1;
    wire signed [38:0] y = s1 + s2;
    assign y_out = y;
endmodule

// _addend_g1_tie with s1 also on a port: only the s2 cell can take the $add.
module _addend_g1_tie_partial (
    input  signed [17:0] a0, b0, c0, a3, b3, c3, a1, b1, a2, b2,
    output signed [37:0] s1_out,
    output signed [38:0] y_out
);
    wire signed [36:0] prev1 = a0 * b0 + c0;
    wire signed [36:0] prev2 = a3 * b3 + c3;
    wire signed [37:0] s1 = a1 * b1 + prev1;
    wire signed [37:0] s2 = a2 * b2 + prev2;
    wire signed [38:0] y = s1 + s2;
    assign s1_out = s1;
    assign y_out = y;
endmodule

// _addend_g1_tie_partial with the heads' and the consumers' lines swapped.
module _addend_g1_tie_partial_swapped (
    input  signed [17:0] a0, b0, c0, a3, b3, c3, a1, b1, a2, b2,
    output signed [37:0] s1_out,
    output signed [38:0] y_out
);
    wire signed [36:0] prev2 = a3 * b3 + c3;
    wire signed [36:0] prev1 = a0 * b0 + c0;
    wire signed [37:0] s2 = a2 * b2 + prev2;
    wire signed [37:0] s1 = a1 * b1 + prev1;
    wire signed [38:0] y = s1 + s2;
    assign s1_out = s1;
    assign y_out = y;
endmodule

// Grouping 2 whose consumer registers its result: the register is after C,
// so k on C is registered with the rest.
module _addend_g2_preg (
    input                clk,
    input  signed [17:0] a0, b0, c0, a1, b1, k,
    output signed [38:0] y_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    reg  signed [38:0] s_r;
    assign y_out = s_r;
    always @(posedge clk) begin
        s_r <= a1 * b1 + t;
    end
endmodule

// A signed link and an unsigned k, k zero-padded to a signed value so the
// $add is signed: the link sign-extends, as PCIN does.
module _addend_g2_k_padded (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input         [17:0] k,
    output signed [39:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [38:0] t = prev + $signed({1'b0, k});
    wire signed [39:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// The same in grouping 1.
module _addend_g1_k_padded (
    input  signed [17:0] a0, b0, a1, b1,
    input         [17:0] k,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    wire signed [37:0] y = s + $signed({1'b0, k});
    assign y_out = y;
endmodule
