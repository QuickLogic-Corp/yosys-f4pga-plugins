yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

# Test DSPv2 multiplier inference
# Each design should produce a single QL_DSPV2 cell after full synthesis

proc test_dspv2_design {top} {
    design -load read
    hierarchy -top ${top}
    synth_ql -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count 1 t:QL_DSPV2
    return
}

read_verilog dspv2_mult.v
design -save read

test_dspv2_design "mult_32x18"
test_dspv2_design "mult_16x9"
test_dspv2_design "mult_20x18_s"
test_dspv2_design "mult_8x8_s"
