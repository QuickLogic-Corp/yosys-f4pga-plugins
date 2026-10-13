# dspv4_trunc_rsub -- C subtracted from a truncated product at full width must
# not fuse into MULT_RSUB_C.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_trunc_rsub.v
hierarchy -top dspv4_trunc_rsub
$PASS_NAME -family qlf_k6n10f -top dspv4_trunc_rsub -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_trunc_rsub
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
# The addition stayed in fabric: the fused shape was refused and the multiply
# alone went into the DSP.
select -assert-min 1 t:adder_carry
