module merged_top(clk);
input wire clk;

top #(
    .WIDTH(16),
    .DEPTH_LOG2(10),
    .PRIME(1752239),
) hammer1(.clk(clk));

top #(
    .WIDTH(9),
    .DEPTH_LOG2(11),
    .PRIME(3347),
) hammer2(.clk(clk));
endmodule
