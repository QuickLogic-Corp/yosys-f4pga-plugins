// Several DSPs whose product registers feed a shared adder chain.
//
// The point of this test is that ONE flop is wanted by TWO DSPs. cc_p_reg is
// the M stage of a_cc*b_cc, and at the same time the C-path operand register of
// the adder that ma1's DSP absorbs. Whichever multiply the matcher offers first
// takes it; the other must not take it as well, or the flop is handed to
// module->remove() twice -- once by pmgen's deferred autoremove and once by the
// operand-chain drain -- which is a segfault rather than a wrong netlist.
//
// Every dspv4_* test before this one was a single-DSP design, so none of them
// could reach that. This shape crashed all 12 cascade_shared_*_regout designs in
// the aurora2 dsp testsuite while the whole unit suite stayed green.
//
// Reduced from tests/designs/dsp_unit_designs/cascade_shared_1reg_regout.
module dspv4_mult_shared_chain (
    input  wire               clk,
    input  wire signed [17:0] a_cc, b_cc,
    input  wire signed [17:0] a1, a2,
    input  wire signed [17:0] b_shared,
    output reg  signed [37:0] p_out
);
    reg signed [17:0] b_shared_reg;
    always @(posedge clk) b_shared_reg <= b_shared;

    // Product registers -- each an M-stage candidate for its own multiply, and
    // an operand register on the C path of the adder that consumes it.
    reg signed [35:0] cc_p_reg, ma1_mul_reg, ma2_mul_reg;
    always @(posedge clk) begin
        cc_p_reg    <= a_cc * b_cc;
        ma1_mul_reg <= a1 * b_shared_reg;
        ma2_mul_reg <= a2 * b_shared_reg;
    end

    wire signed [36:0] ma1_p = ma1_mul_reg + cc_p_reg;
    wire signed [37:0] ma2_p = ma2_mul_reg + ma1_p;
    always @(posedge clk) p_out <= ma2_p;
endmodule
