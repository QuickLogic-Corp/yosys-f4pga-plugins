// Width safety, the boundary. Phase 4, REQ-D2.
//
// The bound in ql-dspv4.cc is
//     w_sum = max(signed_width(p0), signed_width(p1)) + 1
//     B path taken when  w_sum <= DSPV4_AD_B_WIDTH   (18)
// and the comparison is INCLUSIVE. 17-bit signed operands give w_sum = 18,
// which is exactly the bound and must still infer.
//
// This is the off-by-one test. An accidental `<` instead of `<=` costs every
// design sitting exactly on the boundary its pre-adder, silently -- the
// addition just reappears in fabric and nothing says why. Neither
// dspv4_preadd_width_ok nor _width_over notices: one fits with room to
// spare, the other is refused either way.
//
// `b` is 32 bits to force the B path, as in dspv4_preadd_width_ok.
module dspv4_preadd_width_edge (input signed [16:0] d, input signed [16:0] a,
                                input signed [31:0] b,
                                output signed [49:0] p);
  assign p = (d + a) * b;
endmodule
