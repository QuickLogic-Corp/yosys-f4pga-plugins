// Negative test: an unrecognised option must be rejected, not ignored.
// See ioff_badopt.tcl.
module ioff_badopt (
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
