// dspv4_chain_report_synplify -- a link the -synplify bridge makes: d0's
// z_cout drives casc, and d1 reads casc on z_cin.
// d0 multiplies (MODE_BITS 0, feedback 0, output_select 0): y0 = a0 * b0.
// d1 adds z_cin (MODE_BITS bit 71 selects it, feedback 3 adds it,
// output_select 2 outputs the sum): y = a1 * b1 + casc.
module _bridge_pair (
    input  [31:0] a0, a1,
    input  [17:0] b0, b1,
    output [49:0] y0, y
);
    wire [49:0] casc;

    QL_DSPV2 #(
        .MODE_BITS(80'h0)
    ) d0 (
        .a(a0), .b(b0), .c(18'd0), .load_acc(1'b0), .feedback(3'd0), .output_select(3'd0),
        .z(y0), .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
        .a_cin(32'd0), .b_cin(18'd0), .z_cin(50'd0), .z_cout(casc), .a_cout(), .b_cout()
    );

    QL_DSPV2 #(
        .MODE_BITS(80'h00800000000000000000)
    ) d1 (
        .a(a1), .b(b1), .c(18'd0), .load_acc(1'b0), .feedback(3'd3), .output_select(3'd2),
        .z(y), .clk(1'b0), .reset(1'b0), .acc_reset(1'b0),
        .a_cin(32'd0), .b_cin(18'd0), .z_cin(casc), .z_cout(), .a_cout(), .b_cout()
    );
endmodule
