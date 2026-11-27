// dspv4_casc_chain_max_refused -- one multiply-add, only there to give the
// passes a design to run on.
module top (
    input  signed [17:0] a, b, c,
    output signed [36:0] y
);
    assign y = a * b + c;
endmodule
