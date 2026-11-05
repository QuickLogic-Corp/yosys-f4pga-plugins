# dspv4_xpath -- every cross-path shape here folds, and none double-feeds.
#
# The cell counts cannot tell XPATH from the PREADD word P4 used to emit, and
# cannot tell a PREADD word with the shared operand on D from one with it on
# A and B. The Makefile asserts the mode names, and that the double-feed
# check never fired. `adder_carry 0` shows no pre-adder was left in fabric.
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
select -assert-count 5 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 6 t:QL_DSP4_MULT
# wdr: its register is in the B bank, the only register in the design.
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
select -assert-count 0 t:QL_DSP4_B1_DFFRE_18
select -assert-count 0 t:QL_DSP4_A1_DFFRE_32
select -assert-count 0 t:QL_DSP4_A2_DFFRE_32
select -assert-none t:*dff*
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
