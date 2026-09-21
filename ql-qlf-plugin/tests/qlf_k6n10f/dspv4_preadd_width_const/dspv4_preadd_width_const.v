// Width safety with a constant operand. Phase 4, REQ-D2.
//
// `d + 100` with d 17 bits. The interesting part is what the pass actually
// sees: wreduce has already narrowed the constant from the declared 18 bits
// to 8 (B_WIDTH 8, connect \B 8'01100100), so w_sum comes out as
// max(17, 8) + 1 = 18 and the sum fits AD's 18 bits on the B path.
//
// Had the constant stayed 18 bits wide, w_sum would be 19 and this shape
// would be refused -- so a design adding a small constant to a wide operand
// depends on that narrowing having happened. Verified by mutation: replacing
// signed_width() with GetSize() in the w_sum computation does NOT break this
// test, because wreduce got there first. The signed_width call is belt and
// braces for constants; what this test pins is that the constant shape
// infers at all.
//
// `b` is 32 bits to force the B path, as in the other width tests.
module dspv4_preadd_width_const (input signed [16:0] d,
                                 input signed [31:0] b,
                                 output signed [49:0] p);
  assign p = (d + 18'sd100) * b;
endmodule
