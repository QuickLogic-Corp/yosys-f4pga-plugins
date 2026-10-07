// The pre-adder's two register banks, swept together: D depth 0, 1 and 2
// against AD depth 0 and 1.
//
// D is one stage deep in hardware (a single QL_DSP4_D_DFFRE_27), so a design
// that registers D twice keeps the outer stage in fabric. AD is one stage deep
// as well, and sits on the other side of the adder.
//
// Each block has its own inputs so opt_merge cannot collapse two of them into
// one and make a count agree for the wrong reason.
module dspv4_preadd_dreg (
    input clk,
    // D 0 deep, AD 0 deep
    input signed [15:0] d0, input signed [15:0] a0, input signed [15:0] b0,
    output signed [32:0] p0,
    // D 1 deep, AD 0 deep
    input signed [15:0] d1, input signed [15:0] a1, input signed [15:0] b1,
    output signed [32:0] p1,
    // D 2 deep, AD 0 deep -- the outer stage stays outside
    input signed [15:0] d2, input signed [15:0] a2, input signed [15:0] b2,
    output signed [32:0] p2,
    // D 0 deep, AD 1 deep
    input signed [15:0] d3, input signed [15:0] a3, input signed [15:0] b3,
    output signed [32:0] p3,
    // D 1 deep, AD 1 deep -- both banks at once
    input signed [15:0] d4, input signed [15:0] a4, input signed [15:0] b4,
    output signed [32:0] p4,
    // D 2 deep, AD 1 deep
    input signed [15:0] d5, input signed [15:0] a5, input signed [15:0] b5,
    output signed [32:0] p5
);
  reg signed [15:0] d1_s0;
  reg signed [15:0] d2_s0, d2_s1;
  reg signed [15:0] d4_s0;
  reg signed [15:0] d5_s0, d5_s1;
  reg signed [16:0] ad3, ad4, ad5;

  assign p0 = (d0 + a0) * b0;
  assign p1 = (d1_s0 + a1) * b1;
  assign p2 = (d2_s1 + a2) * b2;
  assign p3 = ad3 * b3;
  assign p4 = ad4 * b4;
  assign p5 = ad5 * b5;

  always @(posedge clk) begin
    d1_s0 <= d1;
    d2_s0 <= d2;
    d2_s1 <= d2_s0;
    d4_s0 <= d4;
    d5_s0 <= d5;
    d5_s1 <= d5_s0;
    ad3   <= d3 + a3;
    ad4   <= d4_s0 + a4;
    ad5   <= d5_s1 + a5;
  end
endmodule
