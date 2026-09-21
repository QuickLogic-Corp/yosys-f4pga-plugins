# dspv4_xpath_sub -- cross-path, subtract direction. Phase 4 / REQ-C1.
#
# Companion to dspv4_xpath. The reason both exist is that the direction picks
# a different leaf, and the subtract direction additionally passes through the
# signed-operand guard: an unsigned pre-adder subtract wraps where the DSP
# signs, so the pass refuses it. Asserting PRESUB here proves the guard let a
# legitimately signed shape through, rather than refusing everything.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_xpath_sub.v
hierarchy -top dspv4_xpath_sub
$PASS_NAME -family qlf_k6n10f -top dspv4_xpath_sub -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_xpath_sub
check -assert
# The subtract direction: PRESUB, not PREADD.
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
# Nothing fell back to fabric.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
