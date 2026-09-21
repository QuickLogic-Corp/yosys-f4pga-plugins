# dspv4_sq_neg -- negated-square inference, Phase 4 / REQ-B3.
#
# The assertion with teeth is `adder_carry 0`. A negate that is not folded into
# the ALU is not an error: the design synthesises, simulates and routes with a
# 34-bit carry chain next to the DSP, and only a cell count notices. By this
# point in the flow the $neg has already been lowered, so the surviving carry
# chain is what to count -- checking $neg alone would pass either way.
#
# QL_DSP4_ALU_SUB is the other half: the whole change is that the ALU leaf goes
# from ADD to SUB. Asserting the SUB leaf and zero ADD leaves is what
# distinguishes "the negate was absorbed" from "the negate vanished", which is
# the failure mode the first attempt at this requirement actually produced --
# an output net with no driver at all.
#
# `check -assert` for exactly that reason.
#
# NF-4: the pass is synth_quicklogic upstream and synth_ql in an aurora2 build,
# so the name is discovered rather than hardcoded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_sq_neg.v
hierarchy -top dspv4_sq_neg
$PASS_NAME -family qlf_k6n10f -top dspv4_sq_neg -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_sq_neg
check -assert
# The ALU is doing the negation: SUB, not ADD.
select -assert-count 1 t:QL_DSP4_ALU_SUB
select -assert-count 0 t:QL_DSP4_ALU_ADD
# ...in the same cell as the multiply, not a second DSP.
select -assert-count 1 t:QL_DSP4_MULT
# Squaring routes the operand through the pre-adder to reach both multiplier
# ports (AMULTSEL and BMULTSEL are both set), so the PREADD leaf is expected
# here even though the RTL has no addition in it.
select -assert-count 1 t:QL_DSP4_PREADD
# Nothing fell back to fabric. adder_carry is the one that matters: $neg is
# already gone by here whether or not the fold happened.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$neg
select -assert-count 0 t:\$sub
