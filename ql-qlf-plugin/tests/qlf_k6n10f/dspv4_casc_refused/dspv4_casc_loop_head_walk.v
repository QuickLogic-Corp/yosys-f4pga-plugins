// _loop_head_walk of dspv4_casc_refused, in a file of its own: its fold
// changes with the modules read before it.

// _loop_acc's loop, and a third stage that reads 41 bits of it into a wider
// result.
module _loop_head_walk (
    input                    clk, rst,
    input      signed [17:0] a0, b0, a1, b1, a2, b2,
    output reg signed [49:0] p,
    output     signed [49:0] z_out
);
    wire signed [35:0] prev = a0 * b0;
    always @(posedge clk)
        if (rst) p <= 0;
        else     p <= p + a1 * b1 + prev;
    wire signed [49:0] z = a2 * b2 + $signed(p[40:0]);
    assign z_out = z;
endmodule
