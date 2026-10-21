// An M register and an operand register on different resets, in one multiply.
//
// The M bank shares RSTN with the operand banks (ffb dsp4_top.v:217-251), so
// the two cannot both go in. The operand register is the one left out: the
// adder reads the M register's Q, so leaving M out instead would add the
// product a cycle early. A lost stage shows only in the values, so each
// design is simulated against its RTL with both resets pulsed.
//
//   add  M register between the multiply and the adder
//   out  product register, then a result register; the first takes the M bank
module dspv4_mreg_rst_add (input clk, rstn, rst2n,
                           input signed [15:0] a, b, input signed [33:0] c,
                           output signed [34:0] p);
  reg signed [15:0] aq;
  reg signed [31:0] m;
  always @(posedge clk) begin
    if (!rstn)  aq <= 0;
    else        aq <= a;
    if (!rst2n) m <= 0;
    else        m <= aq * b;
  end
  assign p = m + c;
endmodule

module dspv4_mreg_rst_out (input clk, rstn, rst2n,
                           input signed [15:0] a, b,
                           output reg signed [31:0] p);
  reg signed [15:0] aq;
  reg signed [31:0] m;
  always @(posedge clk) begin
    if (!rstn)  aq <= 0;
    else        aq <= a;
    if (!rst2n) m <= 0;
    else        m <= aq * b;
    p <= m;
  end
endmodule
