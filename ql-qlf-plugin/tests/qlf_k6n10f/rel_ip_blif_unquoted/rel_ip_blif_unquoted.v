module top(input clk, input a, output y0);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0));
endmodule

(* blackbox *)
module rel_ip(input clk, input d, output q);
endmodule
