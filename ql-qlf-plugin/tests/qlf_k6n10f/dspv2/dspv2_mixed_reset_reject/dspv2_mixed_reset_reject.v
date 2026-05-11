// dspv2_mixed_reset_reject
//
// Two input registers with incompatible reset semantics:
//   a_q — plain register (no reset)
//   b_q — synchronous reset to zero
//
// The DSP cell has a single shared reset for all input pipeline
// registers. Absorbing both would force the no-reset register to
// share the reset, changing the design's semantics.
//
// Expected result: only the resettable FF (b_q) is absorbed into
// the DSP _REGIN variant; the no-reset FF (a_q) must remain as an
// external $dff cell.

module dspv2_mixed_reset_reject (
    input         clk,
    input         rst,
    input  signed [31:0] a,
    input  signed [17:0] b,
    output signed [49:0] z
);
    reg signed [31:0] a_q;
    reg signed [17:0] b_q;

    // No-reset register on input A
    always @(posedge clk)
        a_q <= a;

    // Synchronous-reset register on input B
    always @(posedge clk)
        if (rst) b_q <= 18'sd0;
        else     b_q <= b;

    assign z = a_q * b_q;
endmodule
