// Behavioral RTL: input-registered multiply (no wrapper instantiation).
//
// Exercises the full production flow:
//   behavioral $mul → mul2dsp → techmap (clock_i = 1'bx) →
//   ql_dsp -dspv2 (adopts FF clock into cell) → ql_dspv2_types → _REGIN
//
// This catches the bug where the techmap sets clock_i to 1'bx and the
// ql_dsp -dspv2 absorption pass rejects the FF because of the clock
// mismatch. With the fix, the pass adopts the FF's clock, absorption
// succeeds, and the final netlist contains a _REGIN variant.

module dspv2_behavioral_regin (
    input  wire        clk,
    input  wire signed [31:0] a,
    input  wire signed [17:0] b,
    output wire signed [49:0] z
);
    reg signed [31:0] a_q;

    always @(posedge clk)
        a_q <= a;

    assign z = a_q * b;
endmodule
