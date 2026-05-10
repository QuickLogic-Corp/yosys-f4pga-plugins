// Smoke: unsigned operands must NOT infer a DSPv2 MULTACC cell.
//
// The ql_dsp_macc -dspv2 pass rejects unsigned multiplies because the
// QL_DSPV2 datapath is signed-only.  The multiply should still land in
// a DSPv2 MULT cell via the mul2dsp fallback path, but the accumulate
// pattern must NOT be absorbed — the acc logic stays in generic cells.
module dspv2_unsigned_reject (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire        [15:0]    a,
    input  wire         [8:0]    b,
    output reg         [24:0]    z
);
    wire [24:0] mul = a * b;

    always @(posedge clk) begin
        if (rst)
            z <= 25'd0;
        else if (en)
            z <= z + mul;
    end
endmodule
