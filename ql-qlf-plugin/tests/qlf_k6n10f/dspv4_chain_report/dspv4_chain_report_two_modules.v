// Two modules and no top, read with no hierarchy pass: the chain report adds
// up the links and chains of both and takes the longest of either.
(* blackbox *) module QL_DSP4(input [49:0] PCIN, output [49:0] PCOUT, output [49:0] P);
endmodule

// A chain of three, c0 -> c1 -> c2.
module _two_modules_three (
    output [49:0] p0, p1, p2
);
    wire [49:0] link01, link12;
    QL_DSP4 c0 (.PCIN(), .PCOUT(link01), .P(p0));
    QL_DSP4 c1 (.PCIN(link01), .PCOUT(link12), .P(p1));
    QL_DSP4 c2 (.PCIN(link12), .PCOUT(), .P(p2));
endmodule

// A chain of two, c0 -> c1.
module _two_modules_two (
    output [49:0] p0, p1
);
    wire [49:0] link01;
    QL_DSP4 c0 (.PCIN(), .PCOUT(link01), .P(p0));
    QL_DSP4 c1 (.PCIN(link01), .PCOUT(), .P(p1));
endmodule
