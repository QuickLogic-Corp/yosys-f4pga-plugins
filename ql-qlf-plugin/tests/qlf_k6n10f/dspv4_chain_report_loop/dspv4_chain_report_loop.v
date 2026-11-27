// dspv4_chain_report_loop -- PCIN loops, wired by hand, which the chain report
// does not count. One module per block. The cell is a black box with the three
// ports the chain report reads.
(* blackbox *) module QL_DSP4(input [49:0] PCIN, output [49:0] PCOUT, output [49:0] P);
endmodule

// Three cells in a ring: r0 -> r1 -> r2 -> r0.
module _loop3 (
    output [49:0] p0, p1, p2
);
    wire [49:0] link01, link12, link20;
    QL_DSP4 r0 (.PCIN(link20), .PCOUT(link01), .P(p0));
    QL_DSP4 r1 (.PCIN(link01), .PCOUT(link12), .P(p1));
    QL_DSP4 r2 (.PCIN(link12), .PCOUT(link20), .P(p2));
endmodule

// Two cells in a ring, r0 -> r1 -> r0, and tail fed from r1.
module _loop_tail (
    output [49:0] p0, p1, p2
);
    wire [49:0] link01, link10;
    QL_DSP4 r0 (.PCIN(link10), .PCOUT(link01), .P(p0));
    QL_DSP4 r1 (.PCIN(link01), .PCOUT(link10), .P(p1));
    QL_DSP4 tail (.PCIN(link10), .PCOUT(), .P(p2));
endmodule

// Two cells in a ring, r0 -> r1 -> r0, and a separate chain, head -> tail.
module _loop_beside (
    output [49:0] p0, p1, p2, p3
);
    wire [49:0] link01, link10, link_chain;
    QL_DSP4 r0 (.PCIN(link10), .PCOUT(link01), .P(p0));
    QL_DSP4 r1 (.PCIN(link01), .PCOUT(link10), .P(p1));
    QL_DSP4 head (.PCIN(), .PCOUT(link_chain), .P(p2));
    QL_DSP4 tail (.PCIN(link_chain), .PCOUT(), .P(p3));
endmodule
