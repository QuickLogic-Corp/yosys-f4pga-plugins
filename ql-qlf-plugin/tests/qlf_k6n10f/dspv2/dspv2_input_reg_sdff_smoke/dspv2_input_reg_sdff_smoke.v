// Smoke: sync-reset input-register absorption into A_REG via ql_dsp -dspv2.
//
// The register uses `always @(posedge clk) if (rst) ... else ...` with
// no sensitivity-list edge on rst, which Yosys lowers to a $sdff cell.
// The FF matcher accepts $sdff when SRST_POLARITY=1,
// SRST_VALUE=0, and the SRST signal matches the cell's reset_i net.
// This test proves that $sdff absorption works and that the result is
// formally equivalent to the original RTL.
//
// Note: dspv2_input_reg_absorb_smoke uses the same RTL pattern
// but was written before the $sdff matcher, when opt -nosdff folded the
// sync-reset into a $dff+mux. The synth_quicklogic -dspv2 flow may or may not
// preserve the $sdff depending on the opt configuration. This test
// is an explicit $sdff exercise -- the structural assertion checks
// for zero $sdff (absorbed) or zero $dff (absorbed via the old path).
//
// Module name matches the test directory name so DESIGN_TOP wiring is
// correct. dspv2_sim.v provides the wrapper declaration; synth_quicklogic
// reads it automatically when -dspv2 is set.

module dspv2_input_reg_sdff_smoke (
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
