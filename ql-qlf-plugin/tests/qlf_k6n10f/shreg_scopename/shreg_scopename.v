// Two 10-flop shift registers in a row, each in its own instance.
module top (
    input  clk,
    input  d,
    output q
);
  wire mid;
  chain u0 (.clk(clk), .d(d),   .q(mid));
  chain u1 (.clk(clk), .d(mid), .q(q));
endmodule

module chain (
    input  clk,
    input  d,
    output q
);
  reg [9:0] r;
  assign q = r[9];
  always @(posedge clk) r <= {r[8:0], d};
endmodule
