yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_sub_unsigned.v
hierarchy -top dspv4_preadd_sub_unsigned
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_sub_unsigned -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_sub_unsigned
check -assert
# Exactly one of the two folds: the narrow-product one. Counting $sub proves
# nothing -- it is lowered by this point either way, so the surviving carry
# chain is the evidence the wide one stayed in fabric.
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-min 1 t:adder_carry
