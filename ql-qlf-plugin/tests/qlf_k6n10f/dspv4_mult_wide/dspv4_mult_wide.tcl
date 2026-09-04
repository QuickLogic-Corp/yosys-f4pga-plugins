# dspv4_mult_wide -- a 48x32 multiply decomposed across four DSPs.
#
# Asserting the exact count rather than a minimum: four is the minimum number
# of 32x18 tiles that can hold a 48x32 product, so a fifth would mean mul2dsp
# was handed the wrong port widths, and three would mean a piece was left soft.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_wide.v
hierarchy -top dspv4_mult_wide
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_wide -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_wide
check -assert
select -assert-count 4 t:QL_DSP4_MULT
# Nothing was left for the soft multiplier path, and no intermediate cell type
# escaped the chtype round-trip.
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$__soft_mul
select -assert-count 0 t:\$__QL_DSP4_MUL
