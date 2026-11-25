// QL_DSP4 cells wired here by hand, PCOUT to PCIN. No pass makes them. The
// cell is a black box with the three ports the chain report reads.
(* blackbox *) module QL_DSP4(input [49:0] PCIN, output [49:0] PCOUT, output [49:0] P);
endmodule

// A chain of three, c0 -> c1 -> c2, and a chain of two, c3 -> c4.
module _by_hand (
    output [49:0] p0, p1, p2, p3, p4
);
    wire [49:0] link01, link12, link34;
    QL_DSP4 c0 (.PCIN(), .PCOUT(link01), .P(p0));
    QL_DSP4 c1 (.PCIN(link01), .PCOUT(link12), .P(p1));
    QL_DSP4 c2 (.PCIN(link12), .PCOUT(), .P(p2));
    QL_DSP4 c3 (.PCIN(), .PCOUT(link34), .P(p3));
    QL_DSP4 c4 (.PCIN(link34), .PCOUT(), .P(p4));
endmodule

// No PCIN reads a PCOUT: from_p reads source's P, from_input a module input,
// from_constant a constant.
module _not_pcout (
    input  [49:0] in,
    output [49:0] p0, p1, p2, p3
);
    QL_DSP4 source (.PCIN(), .PCOUT(), .P(p0));
    QL_DSP4 from_p (.PCIN(p0), .PCOUT(), .P(p1));
    QL_DSP4 from_input (.PCIN(in), .PCOUT(), .P(p2));
    QL_DSP4 from_constant (.PCIN(50'd5), .PCOUT(), .P(p3));
endmodule

// A constant on a PCOUT is not a source: c0 and c1 read the constant c0's
// PCOUT is tied to.
module _constant_pcout (
    output [49:0] p0, p1
);
    QL_DSP4 c0 (.PCIN(50'd0), .PCOUT(50'd0), .P(p0));
    QL_DSP4 c1 (.PCIN(50'd0), .PCOUT(), .P(p1));
endmodule

// A cell that is not a QL_DSP4 reads c0's PCOUT on a port named PCIN.
(* blackbox *) module OTHER_CELL(input [49:0] PCIN);
endmodule

module _not_dsp_reader (
    output [49:0] p0
);
    wire [49:0] link;
    QL_DSP4 c0 (.PCIN(), .PCOUT(link), .P(p0));
    OTHER_CELL reader (.PCIN(link));
endmodule

// c0 reads, on PCIN, a port named PCOUT of a cell that is not a QL_DSP4.
(* blackbox *) module OTHER_SOURCE(output [49:0] PCOUT);
endmodule

module _not_dsp_source (
    output [49:0] p0
);
    wire [49:0] link;
    OTHER_SOURCE source (.PCOUT(link));
    QL_DSP4 c0 (.PCIN(link), .PCOUT(), .P(p0));
endmodule
