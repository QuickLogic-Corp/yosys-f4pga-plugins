// Phase 4 smoke: dspv2 wrapper with a registered `a_i` input, fed by the
// design's primary input through a $dff. After ql_dsp -dspv2 absorption,
// the cell's A_REG parameter must be 1 and the $dff cell must be gone.
//
// The verilog instantiates the wrapper directly so the test is independent
// of upstream ql_dsp_macc / ql_dsp_simd. dspv2_sim.v supplies the wrapper
// declaration via -lib; only the wrapper instance survives synthesis.
module top (
    input  wire        clk,
    input  wire        rst,
    input  wire signed [15:0] a_in,
    input  wire signed  [8:0] b_in,
    output wire signed [24:0] z_out
);
    reg signed [15:0] a_q;

    always @(posedge clk) begin
        if (rst)
            a_q <= 16'sd0;
        else
            a_q <= a_in;
    end

    dspv2_16x9x32_cfg_ports #(
        .FRAC_MODE (1'b1)
    ) inst (
        .a_i             (a_q),
        .b_i             (b_in),
        .c_i             (9'h0),
        .z_o             (z_out),
        .clock_i         (clk),
        .reset_i         (rst),
        .acc_reset_i     (1'b0),
        .feedback_i      (3'b0),
        .load_acc_i      (1'b0),
        .output_select_i (3'd1),
        .a_cin_i         (16'h0),
        .b_cin_i         (9'h0),
        .z_cin_i         (25'h0)
    );
endmodule
