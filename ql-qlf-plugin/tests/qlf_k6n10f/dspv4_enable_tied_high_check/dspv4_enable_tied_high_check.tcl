# dspv4_enable_tied_high_check -- ql_dsp4_check counts a tied-high enable as a
# net. The warning names the module and the cell, so the Makefile can tell the
# two blocks apart in one log.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_enable_tied_high_check.v
hierarchy -top dspv4_enable_tied_high_check
$PASS_NAME -family qlf_k6n10f -top dspv4_enable_tied_high_check -dspv4 -no_abc9 -lib_path $LIB/
