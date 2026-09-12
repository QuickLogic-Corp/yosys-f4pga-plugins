# dspv4_macc_rsub -- accumulate in the reverse-subtract direction.
#
# Asserting on QL_DSP4_ALU_REV_SUB specifically: this shape is only correct if
# the reverse-subtract leaf was selected AND CIN was tied high, and the leaf
# name is what distinguishes it from the plain subtract of dspv4_macc_sub.
# The arithmetic itself is proved exhaustively by verify_equiv.py.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_rsub.v
hierarchy -top dspv4_macc_rsub
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_rsub -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_rsub
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_REV_SUB
select -assert-count 0 t:QL_DSP4_ALU_SUB
# The accumulator went into the DSP's own bank.
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
# Nothing fell back to fabric.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$sub
