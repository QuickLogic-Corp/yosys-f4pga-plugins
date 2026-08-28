// Direct instantiation of the GPIO v3.0 IO FF primitives (test-plan section 3,
// REQ-A1/REQ-A2/REQ-A4).
//
// This is the manual-instantiation escape hatch: it must work independently of
// ql_ioff promotion. The cells are instantiated in the middle of the design --
// D is not a top-level input and Q has fabric consumers -- so no boundary
// promotion is involved either way.

module direct_sdffr (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    input  wire other,
    output wire q_o
);
    wire d_int;
    wire q;

    assign d_int = d ^ other;
    assign q_o   = q & other;

    io_sdffr ff (
        .C(clk),
        .D(d_int),
        .R(rst_n),
        .Q(q)
    );
endmodule

module direct_sdffnr (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    input  wire other,
    output wire q_o
);
    wire d_int;
    wire q;

    assign d_int = d ^ other;
    assign q_o   = q & other;

    io_sdffnr ff (
        .C(clk),
        .D(d_int),
        .R(rst_n),
        .Q(q)
    );
endmodule
