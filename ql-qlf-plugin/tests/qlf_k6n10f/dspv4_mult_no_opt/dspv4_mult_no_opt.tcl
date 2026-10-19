# dspv4_mult_no_opt -- the DSP-V4 netlist is clean under -no_opt.
#
# -no_opt skips every opt pass, including the `opt -undriven` the default flow
# relied on to turn an open ALU carry-in into a constant. Until ql_dspv4 tied
# CIN itself, every DSP left one undriven wire behind under -no_opt, and no
# -no_opt test could use `check -assert`. This one does.
#
# NF-4: the pass is synth_ql upstream and synth_ql in an aurora2 build,
# so the name is discovered rather than hardcoded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_no_opt.v
hierarchy -top dspv4_mult_no_opt
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_no_opt -dspv4 -no_abc9 -no_opt -lib_path $LIB/

yosys cd dspv4_mult_no_opt
# Every leaf input has a driver: the ALU carry-in included.
check -assert
# The DSP was used and nothing fell back to fabric.
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:\$mul
