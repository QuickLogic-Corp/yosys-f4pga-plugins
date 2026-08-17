// Input for the ql_io_translate pass -- test-plan section 7.
//
// Stands in for a Synplify .vm produced with IO insertion enabled: the boundary
// registers have already been consumed by Synplify into IBUF_FF/OBUF_FF, and the
// job of the pass is only to re-spell that decision as the GPIO v3.0 IO subtile
// primitive.
//
// IBUF_FF/OBUF_FF are declared here rather than pulled from synplify_map.v: the
// plugin's copy of that file does not carry them (only the generated device_data
// copy does), and driving the pass directly keeps the test focused on the rewrite
// rather than on the whole -synplify flow.

(* blackbox *)
module IBUF_FF (output O, input I, input C);
endmodule

(* blackbox *)
module OBUF_FF (output O, input I, input C);
endmodule

// Two input-side and two output-side, so both primitives are exercised and the
// translated count is unambiguous.
module io_translate (
    input  wire       clk,
    input  wire [1:0] pad_in,
    input  wire [1:0] data_in,
    output wire [1:0] pad_out
);
    wire [1:0] mid;
    wire [1:0] outd;

    IBUF_FF u_in0 (.O(mid[0]), .I(pad_in[0]), .C(clk));
    IBUF_FF u_in1 (.O(mid[1]), .I(pad_in[1]), .C(clk));

    assign outd = mid ^ data_in;

    OBUF_FF u_out0 (.O(pad_out[0]), .I(outd[0]), .C(clk));
    OBUF_FF u_out1 (.O(pad_out[1]), .I(outd[1]), .C(clk));
endmodule

// No IO FFs at all, to pin that the pass is inert on a netlist Synplify produced
// with IO insertion disabled -- which is every netlist the aurora flow currently
// generates, since every device template sets -disable_io_insertion 1.
module io_translate_none (
    input  wire       clk,
    input  wire [1:0] pad_in,
    output wire [1:0] pad_out
);
    reg [1:0] q;
    assign pad_out = q;
    always @(posedge clk) q <= pad_in;
endmodule
