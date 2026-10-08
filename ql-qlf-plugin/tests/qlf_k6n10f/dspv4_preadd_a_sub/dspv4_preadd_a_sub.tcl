yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_a_sub.v
hierarchy -top dspv4_preadd_a_sub
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_a_sub -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_a_sub
check -assert
# PRESUB, not PREADD: the direction is the whole point of this test. An add
# leaf here would compute (D + A) * B.
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
# adder_carry, not $sub: $sub is already lowered by here, so counting it
# passes whether or not the fold happened.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$sub
