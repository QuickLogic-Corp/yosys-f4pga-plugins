# dspv4_mult_mreg_add_self -- the registered form of the same shape.
#
# Reaching the assertions at all is most of the test: this script used to abort
# the whole yosys process inside ql_dspv4.
#
# What the netlist must look like afterwards: the multiply in a DSP with its
# product register absorbed into P (QL_DSP4_ACC_DFFRE_64, not the M banks --
# with no adder to fuse, the product register IS the result register), and the
# doubling left in fabric as one 37-bit carry chain.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_mreg_add_self.v
hierarchy -top dspv4_mult_mreg_add_self
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_mreg_add_self -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_mreg_add_self
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
# The product register went into P, not the M banks, and not fabric.
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:QL_DSP4_M_DFFR_50
select -assert-count 0 t:dffre
select -assert-count 0 t:dff
# The addition stayed in fabric, so the registered product still has a driver.
select -assert-count 37 t:adder_carry
