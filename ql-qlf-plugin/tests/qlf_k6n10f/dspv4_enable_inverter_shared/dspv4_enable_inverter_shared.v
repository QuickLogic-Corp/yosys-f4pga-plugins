// An active-low enable that holds several registers.
//
// ql_dspv4 wires each CE pin of a QL_DSP4 from the flop's enable, and puts an
// inverter in front of it when the enable is active-low. It used to make one
// inverter per pin, so one `if (!en_n)` reached four pins through four nets.
// Anything that counts nets, ql_dsp4_check and the techmap's three-net clock
// enable limit among them, saw four enables where the design has one.
//
//   shared  one active-low enable on A, B, C and P: one inverter
//   pairs   two active-low enables, one on A and B, one on C and P: two
//           inverters, since they are different signals
module dspv4_inverter_shared (input clk, input en_n, input [15:0] a, input [15:0] b,
                              input [31:0] c, output reg [47:0] p);
  reg [15:0] ar, br;
  reg [31:0] cr;
  always @(posedge clk) if (!en_n) begin
    ar <= a;
    br <= b;
    cr <= c;
    p <= ar * br + cr;
  end
endmodule

module dspv4_inverter_pairs (input clk, input ab_n, input cp_n, input [15:0] a, input [15:0] b,
                             input [31:0] c, output reg [47:0] p);
  reg [15:0] ar, br;
  reg [31:0] cr;
  always @(posedge clk) if (!ab_n) begin
    ar <= a;
    br <= b;
  end
  always @(posedge clk) if (!cp_n) begin
    cr <= c;
    p <= ar * br + cr;
  end
endmodule
