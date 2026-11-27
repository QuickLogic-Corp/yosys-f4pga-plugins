module leaf (input s, input [1:0] a, output c);
    assign c = s & a[0];
endmodule

module mid (input clk, input [3:0] d, output reg [3:0] q, output y);
    always @(posedge clk) q <= d + 4'd1;
    leaf u_leaf (.s(d[0]), .a(d[2:1]), .c(y));
endmodule

module sreg (input clk, input [1:0] d, output reg r);
    always @(posedge clk) r <= d[0] ^ d[1];
endmodule

module ram (input clk, input we, input [8:0] addr, input [31:0] wd, output reg [31:0] rd);
    reg [31:0] mem [0:511];
    always @(posedge clk) begin
        if (we) mem[addr] <= wd;
        rd <= mem[addr];
    end
endmodule

// u_leaf drives the top port c: its LUT is named after the port, and must still be owned
// by u_leaf. u_m0 and u_m1 compute the same function, so synthesis merges them into one
// LUT, which must get exactly one of the two owners. u_s0 and u_s1 register the same value, so
// synthesis shares one FF between them, which must get one owner too.
module top (input clk, input [3:0] d, input s, input [1:0] a,
            output c, output [3:0] q, output y, output [1:0] g, output m0, output m1,
            input [8:0] ra, input [31:0] rw, output [31:0] rr, output s0, output s1);
    leaf u_leaf (.s(s), .a(a), .c(c));
    leaf u_m0 (.s(d[3]), .a(a), .c(m0));
    leaf u_m1 (.s(d[3]), .a(a), .c(m1));
    mid u_mid (.clk(clk), .d(d), .q(q), .y(y));
    sreg u_s0 (.clk(clk), .d(a), .r(s0));
    sreg u_s1 (.clk(clk), .d(a), .r(s1));
    ram u_ram (.clk(clk), .we(s), .addr(ra), .wd(rw), .rd(rr));
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin : gen
            leaf u (.s(d[i]), .a({d[i+1], d[i+2]}), .c(g[i]));
        end
    endgenerate
endmodule
