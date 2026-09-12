# dspv4_mult_shared_operand -- a shared operand register is copied, not refused.
#
# Three DSPs, three A-side banks, and nothing left in fabric. Asserting the bank
# count as well as the absence of fabric flops: absorbing into ONE bank and
# leaving the other two DSPs reading a deleted register would also show zero
# flops, so the count is what distinguishes a copy from a theft.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_shared_operand.v
hierarchy -top dspv4_mult_shared_operand
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_shared_operand -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_shared_operand
select -assert-count 3 t:QL_DSP4_MULT
# One bank per DSP -- the shared register was copied into all three.
select -assert-count 3 t:QL_DSP4_A2_DFFRE_32
# And the fabric copy is gone, because every reader took one.
select -assert-count 0 t:sdffre
select -assert-count 0 t:dffre
select -assert-count 0 t:\$mul
