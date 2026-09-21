# dspv4_preadd_width_ok -- the pre-adder width proof succeeds. REQ-D2.
#
# Paired with dspv4_preadd_width_edge (boundary) and _width_over (refusal).
# This one exists so the refusal test cannot pass vacuously: if the pass
# started refusing every B-path pre-adder, _width_over would still be green
# and only this test would catch it.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_width_ok.v
hierarchy -top dspv4_preadd_width_ok
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_width_ok -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_width_ok
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
# The addition came inside: no carry chain left behind.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
