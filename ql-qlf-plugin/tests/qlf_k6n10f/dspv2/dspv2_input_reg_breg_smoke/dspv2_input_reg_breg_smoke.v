// Smoke: input-register absorption into B_REG via ql_dsp -dspv2.
//
// Feeds b_i through a $dff from a primary input.  The absorption pass
// must roll the $dff into the wrapper's B_REG, leaving zero $dff cells
// and producing a typed wrapper with the _REGIN suffix (same mechanism
// as A_REG, exercised on the B port).

module dspv2_input_reg_breg_smoke (
    input  wire        clk,
    input  wire        rst,
    input  wire signed [15:0] a_in,
    input  wire signed  [8:0] b_in,
    output wire signed [24:0] z_out
);
    reg signed [8:0] b_q;

    always @(posedge clk) begin
        if (rst)
            b_q <= 9'sd0;
        else
            b_q <= b_in;
    end

    dspv2_16x9x32_cfg_ports #(
        .FRAC_MODE (1'b1)
    ) inst (
        .a_i             (a_in),
        .b_i             (b_q),
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
