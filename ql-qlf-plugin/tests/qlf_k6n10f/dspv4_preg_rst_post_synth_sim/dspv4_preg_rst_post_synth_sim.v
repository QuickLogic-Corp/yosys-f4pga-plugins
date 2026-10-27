// Operand registers and the result register on different resets, in one
// multiply. The operand banks reset on the cell's RSTN, the result (P) bank on
// ACCRSTN alone (ffb dsp4_top.v:399-414), so both go in, each on its own reset.
// A register on the wrong reset shows only when the resets fire, so each design
// is simulated against its RTL with both resets pulsed.
//
//   mul   operand registers on rstn, result register on rst2n
//   acc   accumulator on rst2n, operand registers on rstn
//   addc  C register on rstn, result register on rst2n
module dspv4_preg_rst_mul (input clk, rstn, rst2n,
                           input signed [15:0] a, b,
                           output reg signed [31:0] p);
  reg signed [15:0] aq, bq;
  always @(posedge clk) begin
    if (!rstn)  begin aq <= 0; bq <= 0; end
    else        begin aq <= a; bq <= b; end
    if (!rst2n) p <= 0;
    else        p <= aq * bq;
  end
endmodule

module dspv4_preg_rst_acc (input clk, rstn, rst2n,
                           input signed [15:0] a, b,
                           output reg signed [39:0] p);
  reg signed [15:0] aq, bq;
  always @(posedge clk) begin
    if (!rstn)  begin aq <= 0; bq <= 0; end
    else        begin aq <= a; bq <= b; end
    if (!rst2n) p <= 0;
    else        p <= p + aq * bq;
  end
endmodule

module dspv4_preg_rst_addc (input clk, rstn, rst2n,
                            input signed [15:0] a, b, input signed [33:0] c,
                            output reg signed [34:0] p);
  reg signed [33:0] cq;
  always @(posedge clk) begin
    if (!rstn)  cq <= 0;
    else        cq <= c;
    if (!rst2n) p <= 0;
    else        p <= a * b + cq;
  end
endmodule
