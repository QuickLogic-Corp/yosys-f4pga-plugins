# Shared formal-equivalence harness for the dspv2 lowering flow.
#
# Modelled on tests/qlf_k6n10f/dsp_macc/dsp_macc.tcl::check_equiv but
# specialised for the Yosys-driven dspv2 path:
#   - gate side runs `synth_quicklogic -family qlf_k6n10f -dspv2 -top $top`
#     so we cover the full inference + simd-pack + input-reg-absorb +
#     dspv2_final_map + ql_dspv2_types pipeline.
#   - gate side is then techmapped against the behavioural dspv2_sim.v
#     so equiv_make can compare it against the unsynthesised gold copy.
#   - we run equiv_induct -seq 8 first; if any FFs remain unproven we
#     fall back to equiv_simple as a Tier-3 supplementary pass before the
#     final equiv_status -assert. This matches the W1.6 release-gate
#     contract in the aurora2 DSP_V2_IMPLEMENTATION_PLAN.
#
# Per-test wrapper usage (see W1.7-W1.9 smokes for live examples):
#
#   yosys -import
#   if { [info procs synth_quicklogic] == {} } { plugin -i ql-qlf }
#   yosys -import
#   source [file join [file dirname [info script]] ../dspv2/dspv2_equiv.tcl]
#   read_verilog <design>.v
#   design -save read
#   check_equiv_dspv2 <top_module>
#
# Notes:
#   - opt_expr + opt_clean after the techmap mirror the comment in the v1
#     dsp_macc helper: equiv_induct can hang on the raw post-techmap
#     netlist if these aren't run.
#   - We leave the per-test selectors (e.g. select -assert-count 1 t:QL_DSPV2)
#     to the caller after `design -load postopt`, same convention as
#     dsp_macc.tcl::test_dsp_design.

proc check_equiv_dspv2 {top} {
    hierarchy -top ${top}

    design -save preopt

    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2

    design -stash postopt

    design -copy-from preopt  -as gold A:top
    design -copy-from postopt -as gate A:top

    techmap -wb -autoproc -map +/quicklogic/qlf_k6n10f/cells_sim.v
    techmap -wb -autoproc -map +/quicklogic/qlf_k6n10f/dspv2_sim.v
    yosys proc
    opt_expr
    opt_clean -purge

    async2sync
    equiv_make gold gate equiv

    # Tier-1: bounded sequential induction. Depth 8 is enough to cover
    # the deepest pipeline in the dspv2 wrappers (input-reg + pre-add +
    # mult + post-add + acc + output-reg = 6 stages, +2 slack).
    equiv_induct -seq 8 equiv

    # Tier-3 fallback: equiv_simple cleans up any FFs equiv_induct
    # couldn't resolve (e.g. when reset semantics differ between the
    # behavioural sim model and the inferred wrapper). It's a no-op when
    # everything is already proven.
    equiv_simple equiv

    equiv_status -assert equiv

    return
}
