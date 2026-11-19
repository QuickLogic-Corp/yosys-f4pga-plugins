// _addend_g1_full_port of dspv4_casc_addend_refused, in a file of its own:
// its fold depends on the lines its two multiplies sit on.

// Grouping 1 below an accumulator: only the 50-bit port bounds the source,
// and s holds 40 bits.
module _addend_g1_full_port (
    input                clk, rst,
    input  signed [17:0] a0, b0, a1, b1, k,
    output signed [40:0] y_out
);
    reg signed [39:0] acc;
    always @(posedge clk) begin
        if (rst) acc <= 0;
        else acc <= acc + a0 * b0;
    end
    wire signed [39:0] s = a1 * b1 + acc;
    wire signed [40:0] y = s + k;
    assign y_out = y;
endmodule
