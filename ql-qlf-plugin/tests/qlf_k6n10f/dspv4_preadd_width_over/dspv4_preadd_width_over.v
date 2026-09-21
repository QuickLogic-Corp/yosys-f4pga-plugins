// Width safety, the refusal. Phase 4, REQ-D3. The one that matters.
//
// 18-bit signed operands give w_sum = 19, one bit past AD's 18 on the B path.
// AD wraps rather than saturating, so fusing this would compute a plausible
// wrong answer -- and the netlist would synthesise, pack and route clean.
//
// Measured, with the `w_sum <= DSPV4_AD_B_WIDTH` bound removed from
// ql-dspv4.cc and the plugin rebuilt:
//
//     d=131071 a=131071 b=1  ->  got -2       want 262142
//     d=131071 a=1      b=1  ->  got -131072  want 131072
//     472 mismatches / 2000 random vectors
//
// Three cells, no error, no warning, wrong on a quarter of all inputs. With
// the bound in place the same design is refused and simulates clean.
//
// So the correct result here is the EXPENSIVE one: two DSPs and a fabric
// carry chain. A future change that makes this test's cell count drop is a
// regression, not an optimisation.
module dspv4_preadd_width_over (input signed [17:0] d, input signed [17:0] a,
                                input signed [31:0] b,
                                output signed [49:0] p);
  assign p = (d + a) * b;
endmodule
