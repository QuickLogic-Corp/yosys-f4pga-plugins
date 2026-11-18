// _acc_source of dspv4_casc_refused, in a file of its own: its fold changes
// with the modules read before it.

// An accumulator, then a stage that adds it into a result one bit wider.
module _acc_source (
    input                    clk, rst,
    input      signed [17:0] a, b, c, d,
    output     signed [40:0] s_out
);
    reg signed [39:0] acc;
    always @(posedge clk)
        if (rst) acc <= 0;
        else     acc <= acc + a * b;
    assign s_out = c * d + acc;
endmodule
