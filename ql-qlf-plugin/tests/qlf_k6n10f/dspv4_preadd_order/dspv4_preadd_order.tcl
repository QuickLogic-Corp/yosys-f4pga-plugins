yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_order.v
hierarchy -top dspv4_preadd_order
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_order -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_order
check -assert
# A PREADD leaf here means the subtract was flattened into an add.
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$sub
