# dspv4_preadd_a -- pre-adder inference, Phase 4 step 1.
#
# The assertion with teeth is `adder_carry 0`. A pre-adder that is not inferred
# is not an error: the design synthesises, simulates and routes with the
# addition sitting in fabric, and only a cell count notices. By this point in
# the flow the $add has already been lowered, so the surviving carry chain is
# what to count -- checking $add alone would pass either way.
#
# QL_DSP4_PREADD asserted separately from QL_DSP4_MULT: folding the add into
# the DSP but dropping it from the pre-adder would also show zero adder_carry.
#
# `check -assert` because absorbing the $add deletes its output net, and a fold
# that strands a reader is exactly the failure that produces no error anywhere
# else.
#
# NF-4: the pass is synth_quicklogic upstream and synth_ql in an aurora2 build,
# so the name is discovered rather than hardcoded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_a.v
hierarchy -top dspv4_preadd_a
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_a -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_a
check -assert
# The pre-adder was used, on the add direction rather than the subtract leaf.
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
# ...and it is feeding a multiply in the same cell, not a second DSP.
select -assert-count 1 t:QL_DSP4_MULT
# Nothing fell back to fabric. adder_carry is the one that matters: $add is
# already gone by here whether or not the fold happened.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
