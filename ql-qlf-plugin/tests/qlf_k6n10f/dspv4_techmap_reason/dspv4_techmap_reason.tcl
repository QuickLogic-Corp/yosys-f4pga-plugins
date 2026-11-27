# dspv4_techmap_reason -- ql_dsp4_explain on its own. The pass only warns, so
# this run succeeds; the Makefile reads the warnings. The full-flow test,
# dspv4_techmap_refused_stops, checks the four single-rule messages.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog -lib $LIB/qlf_k6n10f/QL_DSP4.v
read_verilog dspv4_techmap_reason.v
hierarchy -top dspv4_techmap_reason
ql_dsp4_explain
