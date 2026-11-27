// Two instances of an IP linked by -rel_ip_blif, plus one register of the user's own.
module top(input clk, input a, input b, output y0, output y1, output r);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0), .k());
    rel_ip u_ip1(.clk(clk), .d(b), .q(y1), .k());
    reg rr;
    always @(posedge clk) rr <= a & b;
    assign r = rr;
endmodule

(* blackbox *)
module rel_ip(input clk, input d, output q, output k);
endmodule
