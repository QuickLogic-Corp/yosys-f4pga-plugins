# dspv4_mult_fanout -- a product with two readers must still reach a DSP.
#
# The assertion with teeth is the pair: one QL_DSP4_MULT (the multiply was
# inferred) AND both additions still in fabric (neither was fused, so neither
# adder's operand net was deleted from under it). Asserting only the DSP would
# pass on a netlist that swallowed one of the adders.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_fanout.v
hierarchy -top dspv4_mult_fanout
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_fanout -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_fanout
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# Both additions stay in fabric. By this point in the flow the $add cells have
# already been lowered, so the surviving carry chains are what to count -- two
# 32-bit adders, 64 adder_carry cells. Asserting the exact number rather than a
# minimum: 32 would mean one addition had been swallowed.
select -assert-count 64 t:adder_carry
