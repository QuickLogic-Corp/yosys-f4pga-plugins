# dspv2_mac_variants
#
# MAC variant smoke tests for DSPv2.  Mirrors the qlf_k6n10f/dsp_macc
# test suite adapted for the signed-only QL_DSPV2 datapath.
#
# Variants with "clear to product" (clr mux) are NOT inferred as DSPv2
# MACs because the feedback port must be constant for type classification.
# Those patterns fall through to mul2dsp and get a MULT cell for the
# multiply, with the accumulate logic in generic cells.
#
# For some tests the equiv_induct pass seems to hang if opt_expr + opt_clean
# are not invoked after techmapping. Therefore run_synth_dspv2 is used
# instead of the equiv_opt pass.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

# Shared equivalence-check harness.
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

# ---------------------------------------------------------------
# test_mac_dspv2 — run one MAC variant through full dspv2 synth +
#                  equiv check + structural assertions.
# ---------------------------------------------------------------
proc test_mac_dspv2 {top expected_cell_suffix} {
    design -load read
    hierarchy -top $top
    run_synth_dspv2 $top
    design -load postopt
    yosys cd $top
    select -assert-min 1 t:QL_DSPV2${expected_cell_suffix}
    # No leftover generic arithmetic — all consumed by the DSP cell
    select -assert-count 0 t:\$mul
    select -assert-count 0 t:\$add
    select -assert-count 0 t:\$sub
    log ">>> PASS: $top\n"
}

# ---------------------------------------------------------------
# test_mac_dspv2_no_macc — variant with dynamic feedback (clr mux)
#   that cannot be inferred as a MAC. The multiply should still
#   land in a DSPv2 MULT cell via mul2dsp fallback.
# ---------------------------------------------------------------
proc test_mac_dspv2_no_macc {top} {
    design -load read
    hierarchy -top $top
    run_synth_dspv2 $top
    design -load postopt
    yosys cd $top
    # Multiply should be consumed by a DSPv2 MULT cell
    select -assert-min 1 t:QL_DSPV2_*
    select -assert-count 0 t:\$mul
    log ">>> PASS (no-macc): $top\n"
}

read_verilog dspv2_mac_variants.v
design -save read

test_mac_dspv2 dspv2_mac_plain          "_MULTACC"
test_mac_dspv2_no_macc dspv2_mac_clr
test_mac_dspv2 dspv2_mac_arst           "_MULTACC"
test_mac_dspv2 dspv2_mac_ena            "_MULTACC"
test_mac_dspv2_no_macc dspv2_mac_arst_clr_ena
test_mac_dspv2 dspv2_mac_sub            "_MULTACC"
test_mac_dspv2 dspv2_mac_preacc         "_MULTACC"
test_mac_dspv2 dspv2_mac_srst           "_MULTACC"
