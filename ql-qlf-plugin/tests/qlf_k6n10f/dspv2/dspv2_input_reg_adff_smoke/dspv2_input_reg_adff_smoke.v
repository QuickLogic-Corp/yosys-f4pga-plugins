// Smoke: async-reset input-register absorption into A_REG via ql_dsp -dspv2.
//
// The register uses `always @(posedge clk or posedge rst)` which Yosys
// lowers to a $adff cell. The FF matcher accepts $adff
// when ARST_POLARITY=1, ARST_VALUE=0, and the ARST signal matches the
// cell's reset_i net. This test proves that $adff absorption works and
// that the result is formally equivalent to the original RTL.
//
// Module name matches the test directory name so DESIGN_TOP wiring is
// correct. dspv2_sim.v provides the wrapper declaration; synth_quicklogic
// reads it automatically when -dspv2 is set.

module dspv2_input_reg_adff_smoke (
    input  wire        clk,
    input  wire        rst,
    input  wire signed [15:0] a_in,
    input  wire signed  [8:0] b_in,
    output wire signed [24:0] z_out
);
    reg signed [15:0] a_q;

    always @(posedge clk or posedge rst) begin
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
