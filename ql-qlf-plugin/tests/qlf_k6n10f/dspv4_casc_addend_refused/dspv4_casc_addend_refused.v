// dspv4_casc_addend_refused -- stages with a per-stage addend k whose link,
// or whose fold of the $add, is refused. One module per block;
// dspv4_casc_addend_refused.tcl runs each on its own.

// Grouping 1 with a registered link that cannot move: the unregistered sum
// also leaves on a port.
module _addend_reglink (
    input                clk,
    input  signed [17:0] a0, b0, a1, b1, a2, b2, k,
    output signed [38:0] y,
    output signed [36:0] s1_out
);
    reg  signed [36:0] s1_r;
    wire signed [37:0] s = a2 * b2 + s1_r;
    assign y = s + k;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    assign s1_out = s1;
    always @(posedge clk) begin
        s1_r <= s1;
    end
endmodule

// Grouping 2 with the register on t, after the $add.
module _reglink_grp2_creg (
    input                clk,
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] y
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    reg  signed [37:0] t_r;
    assign y = a1 * b1 + t_r;
    always @(posedge clk) begin
        t_r <= t;
    end
endmodule

// Grouping 2 whose prev + k also leaves on a port.
module _addend_shared (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out,
    output signed [37:0] t_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = a1 * b1 + t;
    assign s_out = s;
    assign t_out = t;
endmodule

// Grouping 2 whose t is one bit short of the chain plus k.
module _addend_g2_narrow (
    input  signed [17:0] a0, b0, c0, a, b,
    input  signed [37:0] k,
    output signed [39:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [39:0] s = a * b + t;
    assign s_out = s;
endmodule

// Grouping 1 whose s is one bit short of two products.
module _addend_g1_narrow (
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [35:0] s = a1 * b1 + prev;
    wire signed [37:0] y = s + k;
    assign y_out = y;
endmodule

// Grouping 1 whose s also leaves on a port.
module _addend_g1_shared (
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [36:0] s_out,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    wire signed [37:0] y = s + k;
    assign s_out = s;
    assign y_out = y;
endmodule

// Grouping 2 whose prev is too narrow for the head's range, read into a
// wider stage.
module _addend_g2_link_narrow (
    input  signed [17:0] a0, b0, a, b,
    input  signed [35:0] c,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire signed [35:0] prev = a0 * b0 + c;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = a * b + t;
    assign s_out = s;
endmodule

// Grouping 2 whose prev is unsigned.
module _addend_g2_unsigned (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire        [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// Grouping 1 whose s is unsigned.
module _addend_g1_unsigned (
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire        [36:0] s = a1 * b1 + prev;
    wire signed [37:0] y = s + k;
    assign y_out = y;
endmodule

// Grouping 2 whose stage reads t under a zero pad.
module _addend_g2_pad (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = a1 * b1 + $signed({1'b0, t});
    assign s_out = s;
endmodule

// Grouping 2 whose stage reads t shifted right.
module _addend_g2_slice (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = a1 * b1 + (t >>> 3);
    assign s_out = s;
endmodule

// Grouping 2 whose $add reads prev shifted right.
module _addend_g2_in_slice (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = (prev >>> 5) + k;
    wire signed [38:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// Grouping 2 whose $add reads another cell's bits above prev.
module _addend_g2_in_multicell (
    input  signed [17:0] a0, b0, c0, a1, b1, a2, b2,
    input  signed [36:0] k,
    output signed [49:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [35:0] other = a2 * b2;
    wire signed [48:0] t = $signed({other[10:0], prev}) + k;
    wire signed [49:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// Grouping 2 whose stage reads another cell's bits above t.
module _addend_g2_multicell (
    input  signed [17:0] a0, b0, c0, a1, b1, a2, b2,
    input  signed [36:0] k,
    output signed [49:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [35:0] other = a2 * b2;
    wire signed [37:0] t = prev + k;
    wire signed [49:0] s = a1 * b1 + $signed({other[10:0], t});
    assign s_out = s;
endmodule

// Grouping 2 whose $add reads prev under a zero pad.
module _addend_g2_unsigned_in_pad (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input  signed [36:0] k,
    output signed [39:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [38:0] t = $signed({1'b0, prev}) + k;
    wire signed [39:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// Grouping 1 whose y is one bit wider than the P port.
module _addend_g1_wide_y (
    input  signed [17:0] a0, b0, a1, b1,
    input  signed [49:0] k,
    output signed [50:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    wire signed [50:0] y = s + k;
    assign y_out = y;
endmodule

// Grouping 1 whose consumer registers its result: k on C would be registered
// with the sum, but the RTL adds k after the register.
module _addend_g1_preg (
    input                clk,
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [37:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    reg  signed [36:0] s_r;
    assign y_out = s_r + k;
    always @(posedge clk) begin
        s_r <= a1 * b1 + prev;
    end
endmodule

// A signed link and an unsigned k: the $add is unsigned, so it zero-extends
// the link, and PCIN would sign-extend it.
module _addend_g2_k_unsigned (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input         [17:0] k,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [37:0] t = prev + k;
    wire signed [38:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// The same with t wider than the sum: its top bits are constant zeros.
module _addend_g2_k_unsigned_wide (
    input  signed [17:0] a0, b0, c0, a1, b1,
    input         [17:0] k,
    output signed [40:0] s_out
);
    wire signed [36:0] prev = a0 * b0 + c0;
    wire signed [39:0] t = prev + k;
    wire signed [40:0] s = a1 * b1 + t;
    assign s_out = s;
endmodule

// The same in grouping 1, with y as wide as s.
module _addend_g1_k_unsigned (
    input  signed [17:0] a0, b0, a1, b1,
    input         [17:0] k,
    output signed [36:0] y_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    wire signed [36:0] y = s + k;
    assign y_out = y;
endmodule
