// BLIF acceptance evidence -- test-plan section 7 (REQ-A3, REQ-C4).
//
// This is the direct evidence for "CAD can use the register in the BLIF file",
// and the cheapest place to catch a cell-name or port-set mismatch, which would
// otherwise surface as an obscure VPR failure deep in packing.

module blif_sdffr (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

module blif_sdffnr (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(negedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule
