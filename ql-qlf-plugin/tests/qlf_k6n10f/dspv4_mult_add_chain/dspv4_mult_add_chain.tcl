# dspv4_mult_add_chain -- two chained adders with no accumulator flop.
#
# Regression test. The `acc` slot in ql-dspv4.pmg exists for the second adder
# of A*B + P + C, which only occurs when the chain ends in an accumulator flop.
# Nothing required that flop, so on a plain adder chain `acc` matched an
# ordinary adder and the pass then took C from the wrong operand, never
# expressed that adder's addition, and deleted it anyway -- leaving its result
# net with no driver.
#
# `check -assert` is the assertion that matters here: an undriven net is a
# broken netlist, and it is what the cell counts alone would not catch. The
# design still synthesised, packed and routed in that state, and only turned up
# as wrong values in gate-level simulation.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_add_chain.v
hierarchy -top dspv4_mult_add_chain
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_add_chain -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_add_chain
# Every net has a driver. This is the check the bug failed.
check -assert
# All three products reached a DSP, and both adds were absorbed.
select -assert-count 3 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
