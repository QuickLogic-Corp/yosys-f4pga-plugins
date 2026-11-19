// _loop_acc of dspv4_casc_refused, in a file of its own: its fold changes with
// the modules read before it.

// An accumulating loop fed by a plain product. It folds as two cells that read
// each other's result, so the two links form a loop.
module _loop_acc (
    input                    clk, rst,
    input      signed [17:0] a0, b0, a1, b1,
    output reg signed [49:0] p
);
    wire signed [35:0] prev = a0 * b0;
    always @(posedge clk)
        if (rst) p <= 0;
        else     p <= p + a1 * b1 + prev;
endmodule
