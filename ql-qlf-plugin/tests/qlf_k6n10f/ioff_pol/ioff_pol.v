// Refusal cases and reset-polarity gating -- test-plan sections 5 and 5A
// (REQ-B2, REQ-B6, REQ-B7, REQ-B9, REQ-B10, REQ-B11).
//
// Section 5A is the highest-value part of the plan: because rule R1 declines a
// plain active-high port reset on purpose, a bug that never promotes anything
// looks identical to correct behaviour unless the "correctly declined" and
// "wrongly declined" cases are pinned separately.
//
// One top module per case so `select -assert-count` stays unambiguous.

// -- Section 5: general refusals ---------------------------------------------

// 5.1  Asynchronous reset. The v3.0 IO subtile FF is sync-reset-only.
module async_rst (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

// 5.2  Negedge-clock asynchronous variant of 5.1.
module async_rst_n (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(negedge clk or negedge rst_n)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

// 5.3  Real clock enable. The IO subtile FF has no enable.
module enabled (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (!rst_n)  q <= 1'b0;
        else if (en) q <= pad_in;
endmodule

// 5.4  D has a second consumer in the fabric, so the input port is not
// exclusively feeding the register.
module fanout_d (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o,
    output wire d_copy
);
    reg q;
    assign q_o    = q ^ other;
    assign d_copy = pad_in & other;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

// 5.5  Output-side Q also feeds fabric logic.
module q_used (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output wire q_o,
    output wire q_and
);
    reg q;
    assign q_o   = q;
    assign q_and = q & a;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= a & b;
endmodule

// 5.6  Neither D nor Q touches a top-level port directly.
module not_boundary (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output wire q_o
);
    reg  q;
    wire d;
    assign d   = a & b;
    assign q_o = q ^ a;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= d;
endmodule

// 5.7  Eligible as both input and output IOFF; input promotion is preferred.
module both_paths (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    output wire q_o
);
    reg q;
    assign q_o = q;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

// -- Section 5A: reset polarity ----------------------------------------------

// 5A.1  Active-low reset straight from a port: no inversion needed, promotes.
module rst_lo (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

// 5A.2  Active-high reset straight from a port: satisfying the active-low R pin
// needs a dedicated inverter LUT, so the register stays in the CLB.
module rst_hi (
    input  wire clk,
    input  wire rst,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst) q <= 1'b0;
        else     q <= pad_in;
endmodule

// 5A.3  Negedge-clock variant of 5A.2.
module rst_hi_n (
    input  wire clk,
    input  wire rst,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(negedge clk)
        if (rst) q <= 1'b0;
        else     q <= pad_in;
endmodule

// 5A.4  Active-low reset on an output-side boundary register: promotes.
module rst_lo_out (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output reg  q_o
);
    always @(posedge clk)
        if (!rst_n) q_o <= 1'b0;
        else        q_o <= a & b;
endmodule

// 5A.5  Active-high reset on an output-side boundary register: declined, and
// the output port must not be swapped nor a new cell created.
module rst_hi_out (
    input  wire clk,
    input  wire rst,
    input  wire a,
    input  wire b,
    output reg  q_o
);
    always @(posedge clk)
        if (rst) q_o <= 1'b0;
        else     q_o <= a & b;
endmodule

// 5A.6  No reset at all: there is no polarity to satisfy, so the polarity rule
// must not touch this path.
module resetless (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk) q <= pad_in;
endmodule

// 5A.7  Active-high reset derived from fabric logic. The inversion is absorbed
// into the reset-expression LUT mask, so it costs nothing and the register
// promotes. This is the case where rule R1 and rule R2 disagree.
module rst_hi_expr (
    input  wire clk,
    input  wire rst_a,
    input  wire rst_b,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst_a | rst_b) q <= 1'b0;
        else               q <= pad_in;
endmodule

// 5A.8  Active-low reset derived from fabric logic. Structurally identical to
// 5A.7 -- same cell type, same input count, only the LUT mask differs -- which
// is exactly why R1 promotes both, and why the predicate must key on the LUT
// width rather than on "driver is a LUT" or "driver is not a port".
module rst_lo_expr (
    input  wire clk,
    input  wire rst_a,
    input  wire rst_b,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (!(rst_a | rst_b)) q <= 1'b0;
        else                  q <= pad_in;
endmodule
