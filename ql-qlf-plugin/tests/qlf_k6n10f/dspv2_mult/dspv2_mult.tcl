# Test DSPv2 multiplier inference.
# Each design must produce exactly one QL_DSPV2_MULT subtype cell after the
# unconditional ql_dspv2_types pass that runs at the end of synth_quicklogic.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

proc test_dspv2_design {top} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count 1 t:QL_DSPV2_MULT
    select -assert-count 0 t:QL_DSPV2
    select -assert-count 0 t:QL_DSPV2_MULTACC
    # Acceptance criterion 7: no DSPv1 cells must remain on the -dspv2 path.
    select -assert-count 0 t:QL_DSP2 t:QL_DSP3
    select -assert-count 0 t:dsp_t1_10x9x32 t:dsp_t1_20x18x64
    return
}

# Idempotency smoke test (R-NFR-4): running synth_ql -dspv2 twice on the
# same source must produce the same DSP cell count (one MULT, no unclassified).
proc test_dspv2_idempotent {top} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count 1 t:QL_DSPV2_MULT
    select -assert-count 0 t:QL_DSPV2
    return
}

read_verilog dspv2_mult.v
design -save read

test_dspv2_design "mult_32x18"
test_dspv2_design "mult_16x9"
test_dspv2_design "mult_20x18_s"
test_dspv2_design "mult_8x8_s"

test_dspv2_idempotent "mult_16x9"
