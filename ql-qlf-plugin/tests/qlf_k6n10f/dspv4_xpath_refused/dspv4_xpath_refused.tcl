# dspv4_xpath_refused -- cross-path shapes the pass must refuse.
#
# Kept apart from dspv4_xpath: merged, a count could not tell a refusal from
# a fold that happened in its place. The Makefile asserts the exact modes
# line and each block's stall reason by name.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import
set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]
# A stale netlist from an earlier run must not let the x-grep rule pass on
# nothing: delete it first, so a run that crashes before write_verilog
# leaves no file for `test -s` to find.
file delete -force netlist.v
read_verilog dspv4_xpath_refused.v
hierarchy -top dspv4_xpath_refused
$PASS_NAME -family qlf_k6n10f -top dspv4_xpath_refused -dspv4 -no_abc9 -lib_path $LIB/
yosys cd dspv4_xpath_refused
check -assert
# Every multiply in a DSP, no pre-adder used, the additions in fabric.
select -assert-count 24 t:QL_DSP4_MULT
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
select -assert-min 1 t:adder_carry
select -assert-count 0 t:\$mul
write_verilog -noattr netlist.v
