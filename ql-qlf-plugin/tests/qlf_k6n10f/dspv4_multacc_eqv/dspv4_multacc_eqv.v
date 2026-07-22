// SPDX-License-Identifier: Apache-2.0
//
// P1-VR-1 per-mode equivalence: MULTACC with a CONSTANT load_acc.
//
// DSP-V4 has no dynamic accumulate-load control, so a V2 accumulate mode is only
// supported when load_acc is constant (a variable load_acc hard-errors in the
// pass -- see the dspv4_dynload negative test). This TB checks the supported
// case: load_acc = 1 (accumulate every cycle), with acc_reset used as the
// synchronous accumulator clear.
//
// Mapping under test (ql_dspv2_to_dspv4):
//   V2 MULTACC (feedback=0, output_select=1, load_acc=1 const)  =>
//   QL_DSP4 OPMODE=000100101 (Z=P), PREG=1, CEP=1, ACCRSTN=~acc_reset.
//
// Reference (dspv2_sim.v) vs DUT (dspv4_sim.v) are driven identically and P is
// compared to z every cycle; any mismatch calls $fatal.
//
// SELF-CONTAINED: includes only the three non-colliding files (the qlf_k6n10f
// SIM_LIBS glob does not compile -- dup QL_DSPV2 / dup round / SV-only libmap).
// Run standalone:
//   iverilog -g2012 -o eqv.vvp dspv4_multacc_eqv.v && vvp eqv.vvp

`timescale 1ns / 1ps

`include "../../../qlf_k6n10f/dspv2_sim.v"
`include "../../../qlf_k6n10f/dspv4_sim.v"
`include "../../../qlf_k6n10f/QL_DSP4.v"

module dspv4_multacc_eqv;

    reg         clk = 1'b0;
    reg         reset = 1'b1;      // V2 active-high
    reg         acc_reset = 1'b0;  // V2 active-high (accumulator clear)
    reg  [31:0] a = 32'd0;
    reg  [17:0] b = 18'd0;

    wire [49:0] z_ref;
    wire [49:0] p_dut;
    integer errors = 0;

    always #5 clk = ~clk;

    // Reference: QL_DSPV2 MULTACC, load_acc tied to constant 1 (accumulate).
    QL_DSPV2 #(.MODE_BITS(80'h0)) u_ref (
        .a(a), .b(b), .c(18'h0),
        .load_acc(1'b1), .feedback(3'b000), .output_select(3'b001),
        .z(z_ref), .clk(clk), .reset(reset), .acc_reset(acc_reset),
        .a_cin(32'h0), .b_cin(18'h0), .z_cin(50'h0)
    );

    // DUT: QL_DSP4 with the config word the pass emits for MULTACC.
    QL_DSP4 #(
        .OPMODE(9'b000100101), .ALUMODE(2'b00), .INMODE(5'b00000),
        .CARRYINSEL(3'b000), .USE_SIMD(2'b00),
        .AREG0(1'b0), .AREG1(1'b0), .BREG0(1'b0), .BREG1(1'b0),
        .A_COUT_SEL(1'b0), .B_COUT_SEL(1'b0),
        .CREG(1'b0), .DREG(1'b0), .ADREG(1'b0), .MREG(1'b0), .PREG(1'b1),
        .COUTREG(1'b0), .A_IN_SEL(1'b0), .B_IN_SEL(1'b0),
        .AMULTSEL(1'b0), .BMULTSEL(1'b0), .PREADDINSEL(1'b0),
        .USE_RSS(1'b0), .ROUND(3'b000), .SHIFT(6'b000000), .SATURATE(1'b0)
    ) u_dut (
        .A(a), .B(b), .C(50'h0), .D(27'h0), .CIN(1'b0),
        .PCIN(50'h0), .CCIN(1'b0), .SIGNCIN(1'b0),
        .P(p_dut),
        .CLK(clk), .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1),
        .ARSTN(1'b1), .RSTN(~reset),
        .ACCRSTN(~acc_reset)                 // acc_reset -> ACCRSTN (active-low)
    );

    task check;
        begin
            #1;
            if (p_dut !== z_ref) begin
                errors = errors + 1;
                $display("MISMATCH @%0t: a=%0d b=%0d acc_reset=%b | ref=%0d dut=%0d",
                         $time, a, b, acc_reset, $signed(z_ref), $signed(p_dut));
            end
        end
    endtask

    integer i;
    initial begin
`ifdef VCD_FILE
        $dumpfile(`VCD_FILE); $dumpvars(0, dspv4_multacc_eqv);
`endif
        reset = 1'b1; acc_reset = 1'b0; a = 0; b = 0;
        repeat (3) @(posedge clk);
        @(negedge clk) reset = 1'b0;

        // Phase I: accumulate a*b every cycle.
        a = 32'd3; b = 18'd5;                       // +15/cycle
        for (i = 0; i < 4; i = i + 1) begin @(posedge clk); check; end

        // Phase II: acc_reset clears, then accumulate a new stream.
        @(negedge clk) acc_reset = 1'b1;
        @(posedge clk); check;
        @(negedge clk) acc_reset = 1'b0; a = 32'd7; b = 18'd2;   // +14/cycle
        for (i = 0; i < 3; i = i + 1) begin @(posedge clk); check; end

        if (errors == 0) begin
            $display("=== dspv4_multacc_eqv: MULTACC (const load_acc) equivalence PASSED ===");
            $finish;
        end else begin
            $display("=== dspv4_multacc_eqv: %0d mismatch(es) FAILED ===", errors);
            $fatal(1);
        end
    end

endmodule
