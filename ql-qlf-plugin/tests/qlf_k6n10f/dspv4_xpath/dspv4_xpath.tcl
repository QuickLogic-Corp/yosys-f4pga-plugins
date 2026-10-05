# dspv4_xpath -- cross-path inference, Phase 4 / REQ-C1.
#
# The assertion with teeth is `adder_carry 0`. A pre-adder left in fabric is
# not an error: the design synthesises, simulates and routes, and only a cell
# count notices. By this point $add is already lowered, so the surviving carry
# chain is what to count.
#
# What makes this shape distinct from dspv4_preadd_a is that the pre-adder's
# operand `a` is ALSO the multiplier's other operand. The pmg fanout bound on
# the pre-adder's output and on its inputs has to tolerate that. Tightening
# either bound silently un-fuses this shape, which is why the test exists --
# the shape has no coverage otherwise, and no design in the dsp suite uses it.
#
# NF-4: the pass is synth_quicklogic upstream and synth_ql in an aurora2 build,
# so the name is discovered rather than hardcoded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_xpath.v
hierarchy -top dspv4_xpath
$PASS_NAME -family qlf_k6n10f -top dspv4_xpath -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_xpath
check -assert
# The pre-adder was used, on the add direction.
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
# ...feeding a multiply in the SAME cell, not a second DSP.
select -assert-count 1 t:QL_DSP4_MULT
# Nothing fell back to fabric.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
