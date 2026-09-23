// Promotion of reset-carrying boundary registers into io_sdffr / io_sdffnr --
// test-plan section 4 (REQ-B1, REQ-B3, REQ-B4).
//
// Every reset here is active-low, which is what the IO FF R pin needs natively,
// so all of these promote. The active-high (declined) cases live in ioff_pol.
//
// One top module per case so `select -assert-count` stays unambiguous.

// 4.1  Input-side: D straight from a top-level input, Q used in the fabric.
module in_sdffr (
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

// 4.2  Negedge variant of 4.1.
module in_sdffnr (
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

// 4.3  Output-side: Q reaches a top-level output and nothing else.
module out_sdffr (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output reg  q_o
);
    always @(posedge clk)
        if (!rst_n) q_o <= 1'b0;
        else        q_o <= a & b;
endmodule

// 4.4  Negedge variant of 4.3.
module out_sdffnr (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output reg  q_o
);
    always @(negedge clk)
        if (!rst_n) q_o <= 1'b0;
        else        q_o <= a & b;
endmodule

// 4.5  One input-side and one output-side register in the same module.
module both_sdffr (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    input  wire a,
    output wire q_i,
    output reg  q_out
);
    reg qi;
    assign q_i = qi ^ other;

    always @(posedge clk)
        if (!rst_n) qi <= 1'b0;
        else        qi <= pad_in;

    always @(posedge clk)
        if (!rst_n) q_out <= 1'b0;
        else        q_out <= a ^ other;
endmodule

// 4.6  8-bit registered input port: eight candidates sharing one reset net.
module bus_sdffr (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] pad_in,
    input  wire [7:0] other,
    output wire [7:0] q_o
);
    reg [7:0] q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (!rst_n) q <= 8'b0;
        else        q <= pad_in;
endmodule

// 4.7  Mixed bus: an output-side 8-bit register where bits 0 and 1 also feed
// fabric logic and so are not output-IOFF eligible. D is fabric-derived, which
// keeps every bit off the input-IOFF path. Bits 2..7 promote, 0..1 do not.
module mixed_bus (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] q_o,
    output wire       extra
);
    reg [7:0] q;
    assign q_o   = q;
    assign extra = q[0] ^ q[1];

    always @(posedge clk)
        if (!rst_n) q <= 8'b0;
        else        q <= a & b;
endmodule
