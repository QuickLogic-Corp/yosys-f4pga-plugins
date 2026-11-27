module mac (input clk, input signed [17:0] a, input signed [17:0] b, output reg signed [35:0] p);
    always @(posedge clk) p <= a * b;
endmodule

module cmp (input [7:0] a, input [7:0] b, output eq);
    assign eq = (a ^ b) == 8'ha5;
endmodule

module top (input clk, input signed [17:0] a, input signed [17:0] b, output signed [35:0] p, output eq);
    mac u_mac (.clk(clk), .a(a), .b(b), .p(p));
    cmp u_cmp (.a(a[7:0]), .b(b[7:0]), .eq(eq));
endmodule
