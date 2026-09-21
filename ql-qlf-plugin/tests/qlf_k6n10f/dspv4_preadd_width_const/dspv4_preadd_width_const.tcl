# dspv4_preadd_width_const -- a constant pre-adder operand still infers.
# REQ-D2.
#
# w_sum lands on 18 here, exactly the bound, because wreduce narrowed the
# constant to 8 bits before the pass ran. Mutation-checked: turning the
# bound's `<=` into `<` fails this test (and _edge). Replacing signed_width()
# with GetSize() does NOT -- wreduce already did that narrowing, so for a
# constant operand signed_width is redundant.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_width_const.v
hierarchy -top dspv4_preadd_width_const
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_width_const -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_width_const
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
