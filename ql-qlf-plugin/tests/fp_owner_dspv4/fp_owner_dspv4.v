module mac (input clk, input signed [17:0] a, input signed [17:0] b, output reg signed [35:0] p);
    always @(posedge clk) p <= a * b;
endmodule

module top (input clk, input signed [17:0] a, input signed [17:0] b, output signed [35:0] p);
    mac u_mac (.clk(clk), .a(a), .b(b), .p(p));
endmodule
