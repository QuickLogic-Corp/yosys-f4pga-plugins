// Shared-inverter override and the K threshold -- test-plan section 5B
// (REQ-B12, REQ-B13, REQ-B14).
//
// Every reset here is active-high and taken straight from a port, so rule R1
// declines it and one dedicated inverter LUT serves the whole group. That is
// precisely the situation the override exists for: the inverter's cost is
// shared, so above a group size it is worth paying.
//
// One top module per group width so the threshold can be walked.

// K threshold: group of 1.
module share1 (
    input  wire clk,
    input  wire rst,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst) q <= 1'b0;
        else     q <= pad_in;
endmodule

// K threshold: group of 2.
module share2 (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] pad_in,
    input  wire [1:0] other,
    output wire [1:0] q_o
);
    reg [1:0] q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst) q <= 2'b0;
        else     q <= pad_in;
endmodule

// K threshold: group of 4.
module share4 (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] pad_in,
    input  wire [3:0] other,
    output wire [3:0] q_o
);
    reg [3:0] q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst) q <= 4'b0;
        else     q <= pad_in;
endmodule

// K threshold: group of 8.
module share8 (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] pad_in,
    input  wire [7:0] other,
    output wire [7:0] q_o
);
    reg [7:0] q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst) q <= 8'b0;
        else     q <= pad_in;
endmodule

// Two groups of different width on *different* reset nets. They must be judged
// separately rather than pooled, so at K=4 the 4-wide group promotes and the
// 2-wide one does not.
module share_indep (
    input  wire       clk,
    input  wire       rst_x,
    input  wire       rst_y,
    input  wire [1:0] pad_x,
    input  wire [1:0] other_x,
    input  wire [3:0] pad_y,
    input  wire [3:0] other_y,
    output wire [1:0] qx_o,
    output wire [3:0] qy_o
);
    reg [1:0] qx;
    reg [3:0] qy;
    assign qx_o = qx ^ other_x;
    assign qy_o = qy ^ other_y;

    always @(posedge clk)
        if (rst_x) qx <= 2'b0;
        else       qx <= pad_x;

    always @(posedge clk)
        if (rst_y) qy <= 4'b0;
        else       qy <= pad_y;
endmodule

// One inverter driving eight reset pins, of which only three belong to
// promotable candidates: `deep` has fabric-derived D and fabric-consumed Q, so
// those five registers are not boundary candidates at all. The group therefore
// counts 3, not 8 -- raw net fan-out must not be used.
module share_count (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] pad_in,
    input  wire [2:0] other,
    input  wire [4:0] a,
    input  wire [4:0] b,
    output wire [2:0] q_o,
    output wire [4:0] deep_o
);
    reg [2:0] q;
    reg [4:0] deep;
    assign q_o    = q ^ other;
    assign deep_o = deep & a;

    always @(posedge clk)
        if (rst) q <= 3'b0;
        else     q <= pad_in;

    always @(posedge clk)
        if (rst) deep <= 5'b0;
        else     deep <= a & b;
endmodule

// No reset: K must have no effect on the resetless path.
module share_none (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk) q <= pad_in;
endmodule

// Active-high reset derived from fabric logic: the inversion is absorbed into
// the reset-expression LUT, so R1 never declined it and the override never
// applies. Must promote at every K.
module share_expr (
    input  wire clk,
    input  wire rst_a,
    input  wire rst_b,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst_a | rst_b) q <= 1'b0;
        else               q <= pad_in;
endmodule

// Asynchronous reset outranks the override: no K promotes this.
module share_async (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] pad_in,
    input  wire [3:0] other,
    output wire [3:0] q_o
);
    reg [3:0] q;
    assign q_o = q ^ other;

    always @(posedge clk or posedge rst)
        if (rst) q <= 4'b0;
        else     q <= pad_in;
endmodule

// A real enable outranks the override too.
module share_en (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire [3:0] pad_in,
    input  wire [3:0] other,
    output wire [3:0] q_o
);
    reg [3:0] q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (rst)     q <= 4'b0;
        else if (en) q <= pad_in;
endmodule
