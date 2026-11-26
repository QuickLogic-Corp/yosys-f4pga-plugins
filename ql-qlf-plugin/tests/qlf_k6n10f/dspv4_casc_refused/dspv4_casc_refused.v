// dspv4_casc_refused -- reads of another DSP's result that must not become a
// PCIN link. One module per block; dspv4_casc_refused.tcl runs each on its own.

// A registered link: the next stage reads the sum through a register, and the
// sum before the register also leaves on a port.
module _reglink (
    input                clk,
    input  signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y,
    output signed [36:0] s1_out
);
    reg signed [36:0] s1_r;
    assign y = a2 * b2 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk) s1_r <= s1;
    assign s1_out = s1;
endmodule

// Two registers on the link: the source already has a P register.
module _reglink_two_regs (
    input clk,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y
);
    reg signed [36:0] s1_r, s1_rr;
    assign y = a2 * b2 + s1_rr;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk) begin
        s1_r <= s1;
        s1_rr <= s1_r;
    end
endmodule

// The link register is on another clock than the source's product register.
module _reglink_clock (
    input clk1, clk2,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y
);
    reg signed [36:0] s1_r;
    assign y = a2 * b2 + s1_r;
    reg signed [35:0] m1;
    always @(posedge clk1) m1 <= a1 * b1;
    wire signed [36:0] s1 = m1 + a0 * b0;
    always @(posedge clk2) s1_r <= s1;
endmodule

// Two consumers, each with its own register on another enable. Both
// registers reset, so the RTL and the netlist start alike.
module _reglink_two_consumers_diff (
    input clk, rst, en1, en2,
    input signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    output signed [37:0] y1, y2
);
    reg signed [36:0] s1_ra, s1_rb;
    assign y1 = a2 * b2 + s1_ra;
    assign y2 = a3 * b3 + s1_rb;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk)
        if (rst) s1_ra <= 0;
        else if (en1) s1_ra <= s1;
    always @(posedge clk)
        if (rst) s1_rb <= 0;
        else if (en2) s1_rb <= s1;
endmodule

// Two consumers on one enable, read both ways.
module _reglink_two_consumers_neg_diff (
    input clk, rst, en,
    input signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    output signed [37:0] y1, y2
);
    reg signed [36:0] s1_ra, s1_rb;
    assign y1 = a2 * b2 + s1_ra;
    assign y2 = a3 * b3 + s1_rb;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk)
        if (rst) s1_ra <= 0;
        else if (en) s1_ra <= s1;
    always @(posedge clk)
        if (rst) s1_rb <= 0;
        else if (!en) s1_rb <= s1;
endmodule

// A second register of the sum, behind a port, on another enable than the
// consumer's: it is no copy of the consumer's register.
module _reglink_copy_diff_en (
    input clk, rst, clk_en, other_en,
    input signed [17:0] a0, b0, a1, b1, a2, b2,
    output signed [37:0] y,
    output signed [36:0] s1_out
);
    reg signed [36:0] s1_r, s1_q;
    assign y = a2 * b2 + s1_r;
    wire signed [36:0] s1 = a1 * b1 + a0 * b0;
    always @(posedge clk)
        if (rst) s1_r <= 0;
        else if (clk_en) s1_r <= s1;
    always @(posedge clk)
        if (rst) s1_q <= 0;
        else if (other_en) s1_q <= s1;
    assign s1_out = s1_q;
endmodule

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

// cascade_chain.v: the third sum holds three products in 37 bits, and the last
// stage keeps 38.
module _chain_tight (
    input  signed [17:0] a1, b1_in, a2, b2_in, a3, b3_in, a4, b4_in,
    output signed [37:0] p_out
);
    wire signed [35:0] cc_p = a1 * b1_in;
    wire signed [36:0] ma1_p = (a2 * b2_in) + cc_p;
    wire signed [36:0] ma2_p = (a3 * b3_in) + ma1_p;
    wire signed [37:0] ma3_p = (a4 * b4_in) + ma2_p;
    assign p_out = ma3_p;
endmodule

// A head with a 48-bit fabric addend. The next stage reads 37 bits of its sum
// into a 38-bit result.
module _head_addend (
    input  signed [17:0] a0, b0, a1, b1,
    input  signed [47:0] c0,
    output signed [48:0] p0_out,
    output signed [37:0] s_out
);
    wire signed [48:0] p0 = a0 * b0 + c0;
    assign p0_out = p0;
    wire signed [37:0] s = a1 * b1 + $signed(p0[36:0]);
    assign s_out = s;
endmodule

// An accumulator, a stage that adds all 50 bits of it, and a stage that reads
// 41 bits of that sum into a wider result.
module _full_port_chain (
    input                clk, rst,
    input  signed [17:0] a0, b0, c0, a1, b1, a2, b2,
    output signed [49:0] s2_out, s3_out
);
    reg signed [49:0] p;
    always @(posedge clk)
        if (rst) p <= 0;
        else     p <= p + a0 * b0 + c0;
    wire signed [49:0] s2 = a1 * b1 + p;
    assign s2_out = s2;
    wire signed [49:0] s3 = a2 * b2 + $signed(s2[40:0]);
    assign s3_out = s3;
endmodule

// Four stages. The first and last links read a 37-bit slice into a 38-bit
// result; the middle link reads its source whole.
module _width_reset (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, a3, b3,
    input  signed [47:0] c0,
    output signed [48:0] p0_out,
    output signed [38:0] y_out,
    output signed [37:0] z_out
);
    wire signed [48:0] p0 = a0 * b0 + c0;
    assign p0_out = p0;
    wire signed [37:0] s = a1 * b1 + $signed(p0[36:0]);
    wire signed [38:0] y = a2 * b2 + s;
    assign y_out = y;
    wire signed [37:0] z = a3 * b3 + $signed(y[36:0]);
    assign z_out = z;
endmodule

// A subtracting source, C - A*B: its range holds its C operand too. The sum
// is 36 bits, one short of that range, read into a 38-bit result.
module _sub_source (
    input  signed [17:0] a0, b0, a1, b1, c0,
    output signed [37:0] s_out
);
    wire signed [35:0] prev = c0 - a0 * b0;
    wire signed [37:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// A B-path pre-adder source: a0 is too wide for the B port, so d0 + b0 goes
// there. Its product is one bit wider than a0 * b0. The sum is 38 bits, one
// short of the range, read into a 40-bit result.
module _preadd_b_source (
    input  signed [19:0] a0,
    input  signed [16:0] d0, b0,
    input  signed [17:0] c0, a1, b1,
    output signed [39:0] s_out
);
    wire signed [37:0] prev = (d0 + b0) * a0 + c0;
    wire signed [39:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// A cross-path source, a0 * (d0 + a0): one operand on A, the sum on the B
// side. The next stage reads 34 bits of its 35-bit product into a 36-bit result.
module _xpath_source (
    input  signed [16:0] a0, d0,
    input  signed [17:0] a1, b1,
    output signed [34:0] prev_out,
    output signed [35:0] s_out
);
    wire signed [34:0] prev = a0 * (d0 + a0);
    assign prev_out = prev;
    wire signed [35:0] s = a1 * b1 + $signed(prev[33:0]);
    assign s_out = s;
endmodule

// Two registered sums that feed each other: a loop of two links.
module _loop (
    input                    clk, rst,
    input      signed [17:0] a, b, c, d,
    output reg signed [36:0] p1, p2
);
    always @(posedge clk) if (rst) p1 <= 0; else p1 <= a * b + p2;
    always @(posedge clk) if (rst) p2 <= 0; else p2 <= c * d + p1;
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

// One source per P range row that had no block. In each, the next stage reads
// one bit fewer than the row's range needs, into a wider result: the row
// refuses the link, and a row with a smaller range would make it.

// A reverse-subtracting source, A*B - C. Its range holds its C operand.
module _rsub_source (
    input  signed [17:0] a0, b0, a1, b1, c0,
    output signed [37:0] s_out
);
    wire signed [35:0] prev = a0 * b0 - c0;
    wire signed [37:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// An A-path pre-adder that subtracts: (d0 - a0) is 19 bits, so the product
// is one bit wider than a0 * b0.
module _preadd_a_sub_source (
    input  signed [17:0] d0, a0, b0, a1, b1,
    output signed [36:0] prev_out,
    output signed [37:0] s_out
);
    wire signed [36:0] prev = (d0 - a0) * b0;
    assign prev_out = prev;
    wire signed [37:0] s = a1 * b1 + $signed(prev[35:0]);
    assign s_out = s;
endmodule

// The same with a C operand.
module _preadd_a_sub_c_source (
    input  signed [17:0] d0, a0, b0, c0, a1, b1,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = (d0 - a0) * b0 + c0;
    wire signed [38:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// A B-path pre-adder with no C: a0 is too wide for the B port, so d0 + b0
// goes there.
module _preadd_b_mult_source (
    input  signed [19:0] a0,
    input  signed [16:0] d0, b0,
    input  signed [17:0] a1, b1,
    output signed [37:0] prev_out,
    output signed [38:0] s_out
);
    wire signed [37:0] prev = (d0 + b0) * a0;
    assign prev_out = prev;
    wire signed [38:0] s = a1 * b1 + $signed(prev[36:0]);
    assign s_out = s;
endmodule

// The same, subtracting.
module _preadd_b_sub_source (
    input  signed [19:0] a0,
    input  signed [16:0] d0, b0,
    input  signed [17:0] a1, b1,
    output signed [37:0] prev_out,
    output signed [38:0] s_out
);
    wire signed [37:0] prev = (d0 - b0) * a0;
    assign prev_out = prev;
    wire signed [38:0] s = a1 * b1 + $signed(prev[36:0]);
    assign s_out = s;
endmodule

// The same, subtracting, with a C operand.
module _preadd_b_sub_c_source (
    input  signed [19:0] a0,
    input  signed [16:0] d0, b0,
    input  signed [17:0] c0, a1, b1,
    output signed [39:0] s_out
);
    wire signed [37:0] prev = (d0 - b0) * a0 + c0;
    wire signed [39:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// A cross-path source with the shared operand on B: d0 + b0 is 19 bits, too
// wide for the B side, so the sum goes to the A side.
module _xpath_b_source (
    input  signed [17:0] b0, d0, a1, b1,
    output signed [36:0] prev_out,
    output signed [37:0] s_out
);
    wire signed [36:0] prev = b0 * (d0 + b0);
    assign prev_out = prev;
    wire signed [37:0] s = a1 * b1 + $signed(prev[35:0]);
    assign s_out = s;
endmodule

// One source, two consumers. One reads the source whole; the other reads 36
// of its 37 bits into a 38-bit result, so the width rule refuses that link
// before rule 3 sees it.
module _fanout_narrow (
    input  signed [17:0] a0, b0, a1, b1, a2, b2, c0,
    output signed [37:0] y1, y2
);
    wire signed [36:0] prev = a0 * b0 + c0;
    assign y1 = a1 * b1 + prev;
    assign y2 = a2 * b2 + $signed(prev[35:0]);
endmodule

// An A-path pre-adder that adds, with no C: (d0 + a0) is 19 bits, so the
// product is one bit wider than a0 * b0.
module _preadd_a_mult_source (
    input  signed [17:0] d0, a0, b0, a1, b1,
    output signed [36:0] prev_out,
    output signed [37:0] s_out
);
    wire signed [36:0] prev = (d0 + a0) * b0;
    assign prev_out = prev;
    wire signed [37:0] s = a1 * b1 + $signed(prev[35:0]);
    assign s_out = s;
endmodule

// The same with a C operand.
module _preadd_a_mult_c_source (
    input  signed [17:0] d0, a0, b0, c0, a1, b1,
    output signed [38:0] s_out
);
    wire signed [36:0] prev = (d0 + a0) * b0 + c0;
    wire signed [38:0] s = a1 * b1 + prev;
    assign s_out = s;
endmodule

// The source's A, B and D registers use three enables, and the consumer
// registers the link on a fourth. The move would give the source four distinct
// enables, so the register stays.
module _reglink_enables (
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
    always @(posedge clk) if (en_d) d1_r <= d1;
    always @(posedge clk) if (en_p) s1_r <= s1;
endmodule
