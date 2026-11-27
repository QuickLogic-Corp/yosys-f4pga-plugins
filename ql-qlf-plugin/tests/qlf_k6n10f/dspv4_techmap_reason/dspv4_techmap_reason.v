// ql_dsp4_explain run on its own, on cells that are still QL_DSP4, as if the
// techmap had refused them. Two cases the full flow cannot show together:
//
//   u_two    breaks two rules at once: a CARRYINSEL that is not a carry source
//            and a reserved W encoding. One message names both.
//   u_clean  breaks none of the known rules. The techmap would not refuse it, so
//            a refusal like this means a rule was added to the techmap with no
//            message here. The pass must say so, not stay silent.
module dspv4_techmap_reason (input clk, input [15:0] a, input [15:0] b,
                             output [63:0] p_two, output [63:0] p_clean);
  QL_DSP4 #(.OPMODE(9'b10_000_01_01), .CARRYINSEL(3'b001)) u_two (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_two));
  QL_DSP4 #(.OPMODE(9'b00_000_01_01)) u_clean (
    .CLK(clk), .A({16'b0, a}), .B({2'b0, b}), .CIN(1'b0), .RSTN(1'b1), .ACCRSTN(1'b1), .ARSTN(1'b1),
    .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CED(1'b1), .CEP(1'b1), .P(p_clean));
endmodule
