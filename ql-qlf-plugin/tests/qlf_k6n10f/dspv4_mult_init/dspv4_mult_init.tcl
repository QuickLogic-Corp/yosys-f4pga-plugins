# dspv4_mult_init -- a non-zero power-up value keeps the register in fabric.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_init.v
hierarchy -top dspv4_mult_init
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_init -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_init
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# The DSP's accumulator bank cannot power up at anything but zero.
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
