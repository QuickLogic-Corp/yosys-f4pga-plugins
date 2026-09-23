// A 48x32 multiply: four times wider than one cell's 32x18 ports can hold.
//
// ql_dspv4 alone leaves this as $mul and it goes to fabric whole -- 2952 LUTs.
// mul2dsp.v splits it into 32x18 pieces and a second ql_dspv4 pass puts each
// piece in a DSP. Four is the minimum: ceil(48/31) * ceil(32/17), the 31 and 17
// being what is left of each port once DSP_SIGNEDONLY takes its spare bit.
module dspv4_mult_wide (input signed [47:0] a, input signed [31:0] b,
                        output signed [79:0] p);
  assign p = a * b;
endmodule
