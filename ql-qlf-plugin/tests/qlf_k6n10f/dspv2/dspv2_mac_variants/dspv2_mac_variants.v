// DSPv2 MAC variant testcases — signed-only, 16x9→25 fractured-half.
//
// Mirrors the patterns from qlf_k6n10f/dsp_macc/dsp_macc.v (DSP v1)
// adapted for the QL_DSPV2 signed-only datapath. Each module exercises
// a distinct FF / control combination that ql_dsp_macc -dspv2 must
// handle via the pmgen pattern matcher.

// 1. Plain MAC — no reset, no enable ($dff)
module dspv2_mac_plain (
    input  wire                  clk,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk)
        z <= z + a * b;
endmodule

// 2. MAC with sync clear to product — feedback mux ($dff + $mux)
module dspv2_mac_clr (
    input  wire                  clk,
    input  wire                  clr,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk)
        if (clr) z <=     a * b;
        else     z <= z + a * b;
endmodule

// 3. MAC with async reset to zero ($adff)
module dspv2_mac_arst (
    input  wire                  clk,
    input  wire                  rst,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk or posedge rst)
        if (rst) z <= 25'sd0;
        else     z <= z + a * b;
endmodule

// 4. MAC with enable ($dffe)
module dspv2_mac_ena (
    input  wire                  clk,
    input  wire                  ena,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk)
        if (ena) z <= z + a * b;
endmodule

// 5. MAC with async reset + clear + enable ($adffe + $mux)
module dspv2_mac_arst_clr_ena (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  clr,
    input  wire                  ena,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk or posedge rst)
        if (rst)      z <= 25'sd0;
        else if (ena) begin
            if (clr) z <=     a * b;
            else     z <= z + a * b;
        end
endmodule

// 6. MAC with subtraction ($dff, SUBTRACT=1)
module dspv2_mac_sub (
    input  wire                  clk,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk)
        z <= z - a * b;
endmodule

// 7. MAC with pre-accumulation — combinational output ($dff, out_ff=false)
module dspv2_mac_preacc (
    input  wire                  clk,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output wire signed [24:0]    z
);
    reg signed [24:0] acc;
    assign z = acc + a * b;
    always @(posedge clk)
        acc <= z;
endmodule

// 8. MAC with sync reset to zero — exercises $sdff pmgen path
module dspv2_mac_srst (
    input  wire                  clk,
    input  wire                  rst,
    input  wire signed [15:0]    a,
    input  wire signed  [8:0]    b,
    output reg  signed [24:0]    z
);
    always @(posedge clk)
        if (rst) z <= 25'sd0;
        else     z <= z + a * b;
endmodule
