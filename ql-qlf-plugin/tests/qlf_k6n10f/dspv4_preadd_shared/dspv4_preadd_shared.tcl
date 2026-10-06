yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_shared.v
hierarchy -top dspv4_preadd_shared
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_shared -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_shared
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
# The shared operand must not stop the fold. A surviving carry chain is what
# says it did -- counting $add would pass either way, since $add is gone by here.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
