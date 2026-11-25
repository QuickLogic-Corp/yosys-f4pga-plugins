// dspv4_chain_report_no_dsp -- with -no_dsp the flow skips the DSP steps, so
// no chain length line is printed. dspv4_chain_report's _two is the same RTL
// without the flag.
module _two (
    input  signed [17:0] a, b, c, d,
    output signed [49:0] result
);
    wire signed [35:0] p = a * b;
    assign result = p + c * d;
endmodule
