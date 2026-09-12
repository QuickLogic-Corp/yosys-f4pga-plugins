// (* keep *) on the product. Fusing the adder into the DSP would delete that
// net, which is what the attribute asks synthesis not to do -- so the addition
// stays in fabric and the multiply still gets its DSP, driving the kept wire.
module dspv4_mult_keep (input signed [17:0] a, input signed [17:0] b,
                        input signed [40:0] c, output signed [40:0] s);
  (* keep *) wire signed [35:0] prod = a * b;
  assign s = prod + c;
endmodule
