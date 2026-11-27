# dspv4_techmap_refused_stops -- a QL_DSP4 the techmap refuses must stop
# synthesis. This run is expected to fail (see _negative in the Makefile): the
# step after the DSP-V4 techmap asserts that no QL_DSP4 is left, and the four
# cells in the .v each break a rule, so the error lists all four.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_techmap_refused_stops.v
hierarchy -top dspv4_techmap_refused_stops
$PASS_NAME -family qlf_k6n10f -top dspv4_techmap_refused_stops -dspv4 -no_abc9 -lib_path $LIB/
