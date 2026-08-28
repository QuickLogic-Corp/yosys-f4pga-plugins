// Flag behaviour matrix -- test-plan section 6 (REQ-C2, REQ-D1, REQ-D3).
//
// Both designs are active-low boundary registers, one with a reset and one
// without, so the flag combinations can be walked against a case that would
// otherwise promote.

// Reset-carrying input-side boundary register.
module flag_rst (
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

// Resetless input-side boundary register.
module flag_none (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk) q <= pad_in;
endmodule
