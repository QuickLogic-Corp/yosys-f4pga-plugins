# dspv4_mult_negedge -- a falling-edge register must stay out of the DSP.
#
# Asserting on the fabric flop is the point: the bug absorbed the register, so
# the netlist had a QL_DSP4 accumulator bank and no flop at all. A negedge
# primitive surviving is what proves the edge was preserved.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_negedge.v
hierarchy -top dspv4_mult_negedge
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_negedge -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_negedge
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# No DSP register bank absorbed it ...
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
# ... and it is still a falling-edge flop.
select -assert-min 1 t:sdffnre
