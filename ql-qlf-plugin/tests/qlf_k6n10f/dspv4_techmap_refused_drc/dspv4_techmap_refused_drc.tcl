# dspv4_techmap_refused_drc -- the design rules of the DSP-V4 techmap. This run
# is expected to fail (see _negative in the Makefile): the step after the
# techmap asserts that no QL_DSP4 is left. ql_dsp4_explain runs first and names
# the rule for each of the eight cells in the .v.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_techmap_refused_drc.v
hierarchy -top dspv4_techmap_refused_drc
$PASS_NAME -family qlf_k6n10f -top dspv4_techmap_refused_drc -dspv4 -no_abc9 -lib_path $LIB/
