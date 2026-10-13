# dspv4_mult_add_self -- an adder reading the product twice must not be fused.
#
# The assertion with teeth is the pair: one QL_DSP4_MULT (the multiply still
# reached a DSP) AND the addition still in fabric. Before the fix the adder was
# fused and the carry chain disappeared, so counting adder_carry is what catches
# the regression -- the DSP cell count on its own was 1 either way.
#
# 37 adder_carry is one 37-bit addition. Asserting the exact number rather than
# a minimum: 0 is the broken netlist.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_add_self.v
hierarchy -top dspv4_mult_add_self
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_add_self -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_add_self
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
# The addition stayed in fabric, so the product still has a driver.
select -assert-count 37 t:adder_carry
