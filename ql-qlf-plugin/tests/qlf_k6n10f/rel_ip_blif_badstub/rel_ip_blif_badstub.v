module top(input clk, input [1:0] a, output y0);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0));
endmodule

// The stub declares d as 2 bits; the IP netlist has a 1-bit d.
(* blackbox *)
module rel_ip(input clk, input [1:0] d, output q);
endmodule
