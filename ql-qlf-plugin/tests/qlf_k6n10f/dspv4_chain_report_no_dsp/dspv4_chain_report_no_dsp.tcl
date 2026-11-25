# dspv4_chain_report_no_dsp -- -no_dsp: no chain length line. One block; the
# Makefile's verify line reads its log.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_chain_report_no_dsp.v
hierarchy -top _two
tee -o _two.log $PASS_NAME -family qlf_k6n10f -top _two -dspv4 -no_dsp -no_abc9 -lib_path $LIB/
yosys cd _two
check -assert
