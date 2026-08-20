# dspv4_mult_add -- DSP-V4 inference (ql_dspv4).
#
# VR-3 asserts two things: the DSP was actually used, and nothing was left
# behind in fabric. The second is the one that matters -- a multiply that
# quietly falls back to soft logic is a QoR cliff, not an error, so no other
# check would notice.
#
# The assertions are on the LEAF cells, not on QL_DSP4. synth lowers the
# monolithic cell through dsp4_logical_map.v, so by the end of the flow a
# working design contains QL_DSP4_MULT and friends and no QL_DSP4 at all.
#
# NF-4: the pass is synth_quicklogic upstream and synth_ql in an aurora2 build,
# so the name is discovered rather than hardcoded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_add.v
hierarchy -top dspv4_mult_add
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_add -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_add
# The DSP was used.
select -assert-count 1 t:QL_DSP4_MULT
# Nothing fell back to fabric: no soft arithmetic survives.
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
