// Baseline lock for the ql_ioff pass (test-plan section 2).
//
// ql_ioff had no test coverage at all before this file existed. These designs
// pin the *pre-existing* resetless promotion behaviour so that the
// classify/decide/apply restructure needed for io_sdffr support cannot change
// it silently (REQ-B5, REQ-B11, REQ-C6, RSK-2).
//
// One top module per case so `select -assert-count` stays unambiguous.

// Input-side boundary register, no reset, no enable.
// D comes straight from a top-level input with no other consumer; Q is used in
// the fabric. Promotes to `dff`.
module resetless_in (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk) q <= pad_in;
endmodule

// Negedge variant of resetless_in. Promotes to `dffn`.
module resetless_in_n (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(negedge clk) q <= pad_in;
endmodule

// Output-side boundary register, no reset, no enable.
// Q reaches a top-level output and nothing in the fabric. Promotes to a freshly
// constructed `dff` carrying the `keep` attribute, with the output port name
// moved onto the new wire.
module resetless_out (
    input  wire clk,
    input  wire a,
    input  wire b,
    output reg  q_o
);
    always @(posedge clk) q_o <= a & b;
endmodule

// Negedge variant of resetless_out. Promotes to `dffn`.
module resetless_out_n (
    input  wire clk,
    input  wire a,
    input  wire b,
    output reg  q_o
);
    always @(negedge clk) q_o <= a & b;
endmodule

// Both boundary paths in one module: one input-side and one output-side
// resetless register. Promotes to two `dff` cells.
module resetless_both (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    input  wire a,
    output wire q_i,
    output reg  q_out
);
    reg qi;
    assign q_i = qi & other;

    always @(posedge clk) qi    <= pad_in;
    always @(posedge clk) q_out <= a ^ other;
endmodule
