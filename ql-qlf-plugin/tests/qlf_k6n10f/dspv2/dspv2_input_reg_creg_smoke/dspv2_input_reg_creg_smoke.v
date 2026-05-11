// Smoke: input-register absorption into C_REG via ql_dsp -dspv2.
//
// We instantiate the dspv2_16x9x32_cfg_ports wrapper directly and feed
// c_i through a $dff from a primary input. The synth_quicklogic -dspv2
// flow's `ql_dsp -dspv2` absorption pass must roll the $dff into the
// wrapper's C_REG, leaving zero $dff cells.
//
// PRE_ADD is left at 0 so the design resolves to QL_DSPV2_MULT (the
// preadder sim model does not exist yet). The c_i register absorption
// is orthogonal to the preadder datapath — it tests the run_dspv2()
// C_REG plumbing only.
//
// This complements A_REG (dspv2_input_reg_absorb_smoke) and B_REG
// (dspv2_input_reg_breg_smoke) absorption tests.

module dspv2_input_reg_creg_smoke (
    input  wire        clk,
    input  wire        rst,
    input  wire signed [15:0] a_in,
    input  wire signed  [8:0] b_in,
    input  wire signed  [8:0] c_in,
    output wire signed [24:0] z_out
);
    reg signed [8:0] c_q;

    always @(posedge clk) begin
        if (rst)
            c_q <= 9'sd0;
        else
            c_q <= c_in;
    end

    dspv2_16x9x32_cfg_ports #(
        .FRAC_MODE (1'b1)
    ) inst (
        .a_i             (a_in),
        .b_i             (b_in),
        .c_i             (c_q),
        .z_o             (z_out),
        .clock_i         (clk),
        .reset_i         (rst),
        .acc_reset_i     (1'b0),
        .feedback_i      (3'b0),
        .load_acc_i      (1'b0),
        .output_select_i (3'd0),
        .a_cin_i         (16'h0),
        .b_cin_i         (9'h0),
        .z_cin_i         (25'h0)
    );
endmodule
