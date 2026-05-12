yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

# Test DSPv2 MACC inference
# Each design should produce a single QL_DSPV2 cell with accumulator feedback

proc test_dspv2_macc {top} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count 1 t:QL_DSPV2
    return
}

read_verilog dspv2_macc.v
design -save read

test_dspv2_macc "macc_32x18"
test_dspv2_macc "macc_16x9"
