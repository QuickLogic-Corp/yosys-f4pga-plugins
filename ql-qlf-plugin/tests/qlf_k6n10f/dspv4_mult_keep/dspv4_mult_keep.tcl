# dspv4_mult_keep -- (* keep *) on the product blocks the fusion, not the
# inference.
#
# The kept wire has to survive AND be driven, which is why the DSP count and
# the surviving adder are asserted together: refusing the whole match would
# also leave the adder, but with the multiply in fabric too.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_keep.v
hierarchy -top dspv4_mult_keep
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_keep -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_keep
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# The kept wire is still in the netlist -- this is the whole point of the test,
# and it is what the fusion used to delete.
select -assert-count 1 w:prod
# The addition was not fused, because fusing it would delete the kept product.
# $add is already lowered by this point, so count the carry chain instead.
select -assert-min 1 t:adder_carry
