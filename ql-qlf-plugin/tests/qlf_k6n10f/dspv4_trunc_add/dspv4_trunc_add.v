// The RTL keeps 17 bits of a 35-bit product and then adds it at full width.
// The DSP has no truncation between its multiplier and its ALU, so fusing the
// adder adds the whole product and the dropped bits come back in the sum --
// 3000 of 3000 random vectors wrong on the unguarded pass, with `check` clean.
// The multiply still belongs in a DSP; only the addition has to stay soft.
module dspv4_trunc_add (input [16:0] a, input [17:0] b, input [34:0] c,
                        output [34:0] p);
  wire [16:0] m = a * b;
  assign p = m + c;
endmodule
