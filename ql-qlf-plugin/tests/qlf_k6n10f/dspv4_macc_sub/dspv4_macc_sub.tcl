# dspv4_macc_sub -- accumulate with a subtract (MULT_ACC_SUB).
#
# Asserting on QL_DSP4_ALU_SUB, not just QL_DSP4_MULT: every DSP lowers to some
# ALU leaf, so the DSP being present proves nothing about the direction. This
# shape is only right if the subtract direction was actually selected.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_sub.v
hierarchy -top dspv4_macc_sub
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_sub -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_sub
# The DSP was used, and in the subtract direction.
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_SUB
select -assert-count 0 t:QL_DSP4_ALU_ADD
# The accumulator went into the DSP's own bank.
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
# Nothing fell back to fabric.
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
