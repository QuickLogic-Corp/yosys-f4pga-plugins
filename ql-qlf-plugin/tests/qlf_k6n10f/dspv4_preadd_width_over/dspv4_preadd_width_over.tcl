# dspv4_preadd_width_over -- the pre-adder width guard fires. REQ-D3.
#
# Negative test, and the load-bearing one of the width group. The sum needs 19
# bits and AD holds 18 on the B path, so the pre-adder must NOT be fused.
#
# This guard has been confirmed to fire: with the bound removed the design
# fuses into one DSP and returns the wrong value on 472 of 2000 random
# vectors, including -2 where 262142 was expected. Same discipline as
# dspv4_mult_shared_chain, which was verified to segfault with its guard
# removed. A guard nobody has seen fail is a guard nobody knows works.
#
# `QL_DSP4_PREADD 0` is the assertion. The cell counts around it are
# deliberately loose -- how the refused multiply gets split is an
# implementation detail, but the pre-adder staying out is the requirement.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_width_over.v
hierarchy -top dspv4_preadd_width_over
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_width_over -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_width_over
check -assert
# The pre-adder was refused. This is the requirement.
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
# The multiply still reached a DSP -- the refusal cost the adder, not the DSP.
select -assert-min 1 t:QL_DSP4_MULT
# ...and the addition is still in the design, in fabric, where it belongs.
select -assert-min 1 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
