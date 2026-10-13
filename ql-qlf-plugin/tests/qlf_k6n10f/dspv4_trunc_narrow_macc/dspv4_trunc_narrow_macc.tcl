# dspv4_trunc_narrow_macc -- an accumulator no wider than the truncated
# product is exact and must still be absorbed.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_trunc_narrow_macc.v
hierarchy -top dspv4_trunc_narrow_macc
$PASS_NAME -family qlf_k6n10f -top dspv4_trunc_narrow_macc -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_trunc_narrow_macc
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
# Nothing is read above the cut, so the whole shape folds: no soft adder.
select -assert-count 0 t:adder_carry
