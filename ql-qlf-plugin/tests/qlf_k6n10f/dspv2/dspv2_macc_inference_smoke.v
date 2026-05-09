// Smoke: signed 16x9 multiply-accumulate inference (ql_dsp_macc -dspv2).
// Should infer this as a single dspv2_16x9x32_cfg_ports cell
// with FRAC_MODE=1 and SUBTRACT=0.
module top (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    wire signed [24:0] mul = a * b;

    always @(posedge clk) begin
        if (rst)
            z <= 25'sd0;
        else if (en)
            z <= z + mul;
    end
endmodule
