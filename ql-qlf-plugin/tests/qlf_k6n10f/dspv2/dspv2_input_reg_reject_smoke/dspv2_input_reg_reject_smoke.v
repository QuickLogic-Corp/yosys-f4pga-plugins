// Negative test: a $dff on a_i clocked by a DIFFERENT clock than the
// wrapper's clock_i.  The clock-domain check in run_dspv2() rejects
// this DFF, so it remains in the netlist as a standalone cell.

module dspv2_input_reg_reject_smoke (
    input  wire        clk,
    input  wire        clk2,
    input  wire        rst,
    input  wire signed [15:0] a_in,
    input  wire signed  [8:0] b_in,
    output wire signed [24:0] z_out
);
    reg signed [15:0] a_q;

    // DFF on a different clock — must NOT be absorbed
    always @(posedge clk2) begin
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
