// dspv4_casc_links -- chains the pass links, and one it must leave alone.
// One module per block; dspv4_casc_links.tcl runs each on its own.

// A two-stage chain written by hand, in the shape the pass itself would make:
// the second cell is MULT_ADD_C and its C is the first cell's P, sign-extended
// from 36 bits. The pass did not make these cells, so it must not link them.
module _macro (
    input  signed [17:0] a0, b0, a1, b1,
    output signed [36:0] y
);
    wire [49:0] head_p;
    wire [49:0] tail_p;
    assign y = tail_p[36:0];

    QL_DSP4 #(
        .OPMODE(9'b000000101)
    ) head (
        .A({{14{a0[17]}}, a0}),
        .B(b0),
        .CIN(1'b0),
        .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
        .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1),
        .P(head_p)
    );

    QL_DSP4 #(
        .OPMODE(9'b000110101)
    ) tail (
        .A({{14{a1[17]}}, a1}),
        .B(b1),
        .C({{14{head_p[35]}}, head_p[35:0]}),
        .CIN(1'b0),
        .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
        .ARSTN(1'b1), .RSTN(1'b1), .ACCRSTN(1'b1),
        .P(tail_p)
    );
endmodule

// Five stages. Each sum is as wide as the range of the wires added so far
// needs: 36, 37, 38, 38 and 39 bits.
module _chain (
    input  signed [17:0] a1, b1, a2, b2, a3, b3, a4, b4, a5, b5,
    output signed [38:0] p_out
);
    wire signed [35:0] s1 = a1 * b1;
    wire signed [36:0] s2 = (a2 * b2) + s1;
    wire signed [37:0] s3 = (a3 * b3) + s2;
    wire signed [37:0] s4 = (a4 * b4) + s3;
    wire signed [38:0] s5 = (a5 * b5) + s4;
    assign p_out = s5;
endmodule

// Two stages: a bare product, then a multiply that adds it.
module _two (
    input  signed [17:0] a0, b0, a1, b1,
    output signed [36:0] s_out
);
    wire signed [35:0] prev = a0 * b0;
    wire signed [36:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// Three 32 x 18 stages, every sum 50 bits. By the formula the head's range
// already needs 51 bits; the 50-bit port is the ceiling.
module _wide_chain (
    input  signed [31:0] a0, a1, a2,
    input  signed [17:0] b0, b1, b2, c0,
    output signed [49:0] s2_out
);
    wire signed [49:0] prev = a0 * b0 + c0;
    wire signed [49:0] s1 = a1 * b1 + prev;
    wire signed [49:0] s2 = a2 * b2 + s1;
    assign s2_out = s2;
endmodule

// Three stages. The tail keeps 36 bits and reads 36 bits of a 37-bit sum.
module _trunc (
    input  signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [36:0] s0_out,
    output signed [35:0] s1_out
);
    wire signed [35:0] p0 = a0 * b0;
    wire signed [36:0] s0 = a1 * b1 + p0;
    assign s0_out = s0;
    wire signed [35:0] s1 = a2 * b2 + s0;
    assign s1_out = s1;
endmodule

// A registered link, the consumer written first: the matcher puts the register
// in the consumer's C bank, and step 0 moves it to the source's P bank.
module _reglink_move (
    input clk,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y
);
    reg signed [36:0] s1_r;
    assign y = a2 * b2 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk) s1_r <= s1;
endmodule

// The same, with an enable and a reset on the register, and a product register
// in the source on the same clock.
module _reglink_move_en (
    input clk, rst, en,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y
);
    reg signed [36:0] s1_r;
    assign y = a2 * b2 + s1_r;
    reg signed [35:0] m1;
    always @(posedge clk) m1 <= a1 * b1;
    wire signed [36:0] s1 = m1 + a0 * b0;
    always @(posedge clk)
        if (rst) s1_r <= 0;
        else if (en) s1_r <= s1;
endmodule

// The same, with the registered sum also on a port: the matcher leaves a copy
// of the register in fabric for it.
module _reglink_matcher_copy (
    input clk,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y,
    output signed [36:0] s1_out
);
    reg signed [36:0] s1_r;
    assign y = a2 * b2 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk) s1_r <= s1;
    assign s1_out = s1_r;
endmodule

// A registered link, the source written first: the matcher already puts the
// register in the source's P bank.
module _reglink_preg (
    input clk,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y
);
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    reg signed [36:0] s1_r;
    always @(posedge clk) s1_r <= s1;
    assign y = a2 * b2 + s1_r;
endmodule

// One result read by two stages. Each stage's own adder keeps the head from
// claiming it.
module _fanout (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, c0,
    output signed [37:0] y1, y2
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y1 = a1 * b1 + prev;
    assign y2 = a2 * b2 + prev;
endmodule

// The head's result also leaves on a port.
module _head_fanout (
    input  signed [17:0] a0, b0, a1, b1, c0,
    output signed [36:0] prev_out,
    output signed [37:0] y
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign prev_out = prev;
    assign y = a1 * b1 + prev;
endmodule

// A product register in every stage.
module _mreg (
    input                clk,
    input  signed [17:0] a0, b0, a1, b1, a2, b2, c0,
    output signed [38:0] y
);
    reg signed [35:0] m0, m1, m2;
    always @(posedge clk) begin
        m0 <= a0 * b0;
        m1 <= a1 * b1;
        m2 <= a2 * b2;
    end
    wire signed [36:0] s0 = m0 + c0;
    wire signed [37:0] s1 = m1 + s0;
    assign y = m2 + s1;
endmodule

// Two consumers that register one sum the same way: one register serves both.
module _reglink_two_consumers (
    input                clk,
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    output signed [37:0] y1, y2
);
    reg signed [36:0] s1_r;
    assign y1 = a2 * b2 + s1_r;
    assign y2 = a3 * b3 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk) s1_r <= s1;
endmodule

// The same behind an active-low enable: one signal, one $not per consumer.
module _reglink_two_consumers_neg (
    input                clk, en_n,
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    output signed [37:0] y1, y2
);
    reg signed [36:0] s1_r;
    assign y1 = a2 * b2 + s1_r;
    assign y2 = a3 * b3 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk) if (!en_n) s1_r <= s1;
endmodule

// The same behind a sync reset: one signal, one $not per consumer.
module _reglink_two_consumers_rst (
    input                clk, rst,
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    output signed [37:0] y1, y2
);
    reg signed [36:0] s1_r;
    assign y1 = a2 * b2 + s1_r;
    assign y2 = a3 * b3 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk)
        if (rst) s1_r <= 0;
        else     s1_r <= s1;
endmodule

// One result read by two stages, one of which feeds a third: the link goes to
// the longer chain, though its consumer's name sorts after the other's.
module _fanout_longest (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3, c0,
    output signed [37:0] y2,
    output signed [38:0] z
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y2 = a2 * b2 + prev;
    wire signed [37:0] y1 = a1 * b1 + prev;
    assign z = a3 * b3 + y1;
endmodule

// Two chains of unequal length in one module: four stages and two. The report
// names the longer one.
module _chains_unequal (
    input  signed [17:0] a1, b1, a2, b2, a3, b3, a4, b4, a5, b5, a6, b6,
    output signed [37:0] p_out,
    output signed [36:0] q_out
);
    wire signed [35:0] s1 = a1 * b1;
    wire signed [36:0] s2 = (a2 * b2) + s1;
    wire signed [37:0] s3 = (a3 * b3) + s2;
    wire signed [37:0] s4 = (a4 * b4) + s3;
    assign p_out = s4;
    wire signed [35:0] t1 = a5 * b5;
    wire signed [36:0] t2 = a6 * b6 + t1;
    assign q_out = t2;
endmodule

// One result read by two stages. The stage that heads the longer chain reads
// it through a register, which cannot move into the source: the other stage
// reads the source's result too. So the link goes to the other stage.
module _fanout_filtered (
    input                clk,
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3, c0,
    output signed [37:0] y_b,
    output signed [38:0] z
);
    reg  signed [36:0] prev_r;
    wire signed [37:0] y_a = a1 * b1 + prev_r;
    assign z = a3 * b3 + y_a;
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y_b = a2 * b2 + prev;
    always @(posedge clk) begin
        prev_r <= prev;
    end
endmodule

// The source's A, B and D registers use two enables, D sharing A's, and the
// consumer registers the link on a third. The move gives the source three
// distinct enables, so it happens.
module _reglink_enables_ok (
    input clk, en_a, en_b, en_d, en_p,
    input signed [17:0] a1, b1, d1, a2, b2,
    output signed [37:0] y
);
    reg signed [36:0] s1_r;
    reg signed [17:0] a1_r, b1_r, d1_r;
    assign y = a2 * b2 + s1_r;
    wire signed [36:0] s1 = (a1_r + d1_r) * b1_r;
    always @(posedge clk) if (en_a) a1_r <= a1;
    always @(posedge clk) if (en_b) b1_r <= b1;
    always @(posedge clk) if (en_a) d1_r <= d1;
    always @(posedge clk) if (en_p) s1_r <= s1;
endmodule
