# dspv4_preadd_modes -- one shape per pre-adder mode that folds completely.
#
# The mode line asserted from tests/Makefile is what carries this test. Cell
# counts cannot tell PREADD_A_SUB_B from PREADD_B_SUB_A, and for `order` the
# mode name is the only evidence the operands were not swapped: subtract does
# not commute, so (A - D) * B folding as PREADD_A_SUB_B means D stayed on D.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_modes.v
hierarchy -top dspv4_preadd_modes
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_modes -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_modes
check -assert
# Two adds and three subtracts, one DSP each.
select -assert-count 2 t:QL_DSP4_PREADD
select -assert-count 3 t:QL_DSP4_PRESUB
select -assert-count 5 t:QL_DSP4_MULT
# One ALU per multiply; the +C shape uses its Z input rather than another cell.
select -assert-count 5 t:QL_DSP4_ALU_ADD
# Nothing left soft is what "folded completely" means here.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
