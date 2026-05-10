// Smoke: input-register absorption into A_REG via ql_dsp -dspv2.
//
// We instantiate the dspv2_16x9x32_cfg_ports wrapper directly and feed
// a_i through a $dff fed by a primary input. The synth_quicklogic -dspv2
// flow's `ql_dsp -dspv2` absorption pass must roll the $dff into the
// wrapper's A_REG, leaving zero $dff cells and producing a typed wrapper
// with the _REGIN suffix.
//
// This deliberately bypasses ql_dsp_macc / ql_dsp_simd inference so the
// test is a clean, isolated proof of just the absorption stage
// (orthogonal to inference and SIMD-packing smoke tests).
//
// Module name matches the test directory name so DESIGN_TOP wiring is
// correct. dspv2_sim.v provides the wrapper declaration; synth_quicklogic
// reads it automatically when -dspv2 is set.

module dspv2_input_reg_absorb_smoke (
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
