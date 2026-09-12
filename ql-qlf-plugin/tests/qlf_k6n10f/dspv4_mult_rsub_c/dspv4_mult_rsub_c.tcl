# dspv4_mult_rsub_c -- A*B - C (MULT_RSUB_C).
#
# The leaf assertion is the point: QL_DSP4_ALU_REV_SUB rather than
# QL_DSP4_ALU_SUB is what separates A*B - C from C - A*B, and getting it
# backwards would negate the result while leaving every cell count identical.
# verify_equiv.py proves the arithmetic over all inputs (shape mult_rsub_c).
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_rsub_c.v
hierarchy -top dspv4_mult_rsub_c
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_rsub_c -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_rsub_c
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_REV_SUB
select -assert-count 0 t:QL_DSP4_ALU_SUB
# Nothing fell back to fabric.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$sub
