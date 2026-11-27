module mem (input clk, input wce, input [9:0] wa, input [17:0] wd, input rce, input [9:0] ra, output reg [17:0] rq);
    (* no_rw_check = 1 *) reg [17:0] memory [0:1023];
    always @(posedge clk) begin
        if (rce) rq <= memory[ra];
        if (wce) memory[wa] <= wd;
    end
endmodule

module top (input clk, input wce, input [9:0] wa, input [17:0] wd0, input [17:0] wd1, input rce, input [9:0] ra,
            output [17:0] rq0, output [17:0] rq1);
    mem u_a (.clk(clk), .wce(wce), .wa(wa), .wd(wd0), .rce(rce), .ra(ra), .rq(rq0));
    mem u_b (.clk(clk), .wce(wce), .wa(wa), .wd(wd1), .rce(rce), .ra(ra), .rq(rq1));
endmodule
