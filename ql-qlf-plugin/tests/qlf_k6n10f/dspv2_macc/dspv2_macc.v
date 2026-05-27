// Multiply-accumulate designs for DSPv2 MACC inference

// Basic 32x18 MAC -- wider than 16x9, so MVP (2026.2 release) only infers the
// multiplier as QL_DSPV2_MULT; the accumulator FF stays in fabric.
module macc_32x18 (
    input             clk,
    input             rst,
    input  signed [31:0] a,
    input  signed [17:0] b,
    output reg signed [63:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else
            z <= z + a * b;
endmodule

// Baseline 16x9 MAC (signed, sync reset, no enable) -- QL_DSPV2_MULTACC.
module macc_16x9 (
    input             clk,
    input             rst,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [31:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else
            z <= z + a * b;
endmodule

// Subtractive 16x9 MAC (z <= z - a*b) -- still QL_DSPV2_MULTACC; SUBTRACT=1.
// Exercises R-MACC-2d "SUBTRACT".
module macc_16x9_sub (
    input             clk,
    input             rst,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [31:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else
            z <= z - a * b;
endmodule

// Enable-gated 16x9 MAC -- the $dffe enable becomes load_acc_i.
// Exercises R-MACC-2d "load_acc_i".
module macc_16x9_en (
    input             clk,
    input             rst,
    input             en,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [31:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else if (en)
            z <= z + a * b;
endmodule

// Async-reset 16x9 MAC -- $adff -> reset_i.
// Exercises R-MACC-2d "reset_i = ARST from an $adff".
module macc_16x9_arst (
    input             clk,
    input             arst,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [31:0] z
);
    always @(posedge clk or posedge arst)
        if (arst)
            z <= 0;
        else
            z <= z + a * b;
endmodule

// Unsigned 16x9 MAC -- DSPv2 is signed-only (R-MACC-2a). ql_dsp_macc -dspv2
// must reject this match; the multiply falls through to mul2dsp and is mapped
// as a plain QL_DSPV2_MULT, with the accumulator FF left in fabric.
module macc_16x9_unsigned (
    input             clk,
    input             rst,
    input  [15:0] a,
    input  [8:0]  b,
    output reg [31:0] z
);
    always @(posedge clk)
        if (rst)
            z <= 0;
        else
            z <= z + a * b;
endmodule

// Accumulator-clear via a $mux (clear ? 0 : (z + a*b)). R-MACC-2b says
// ql_dsp_macc -dspv2 must reject the $mux pattern; the result is a plain
// QL_DSPV2_MULT with FF in fabric.
module macc_16x9_clearmux (
    input             clk,
    input             clr,
    input  signed [15:0] a,
    input  signed [8:0]  b,
    output reg signed [31:0] z
);
    always @(posedge clk)
        z <= clr ? 32'sd0 : (z + a * b);
endmodule
