// Negative test: an invalid -min_shared_reset value must be a clean log_error,
// not a silent clamp to 0. See ioff_badval.tcl.
//
// The design itself is irrelevant; the pass must reject its argument before it
// does anything. A non-numeric value takes the same code path.
module ioff_badval (
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
