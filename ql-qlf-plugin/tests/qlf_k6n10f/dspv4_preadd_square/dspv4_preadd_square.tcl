# dspv4_preadd_square -- a pre-adder that feeds both multiply operands
# (squaring) is refused and stays in fabric. Two blocks, see the .v.
#
# `QL_DSP4_PREADD 0` is the assertion. The cell counts around it are
# deliberately loose -- how the refused multiply gets split is an
# implementation detail, but the pre-adder staying out is the requirement.
#
# The registered block is aurora2 #2807: plugin 89a612e aborted on it. Its
# register must end up copied into the DSP banks, the step that aborted. The
# Makefile checks that log line and that no DSP input in the netlist is x.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

# A run that aborts before write_verilog must leave no netlist behind.
file delete -force netlist.v
read_verilog dspv4_preadd_square.v
hierarchy -top dspv4_preadd_square
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_square -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_square
check -assert
# The pre-adder was refused. This is the requirement.
# The multiply still reached a DSP -- the refusal cost the adder, not the DSP.
# ...and the addition is still in the design, in fabric, where it belongs.
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
select -assert-min 1 t:adder_carry
# The registered sum splits over two DSPs, and each takes a copy of the
# register on both operand ports.
select -assert-count 2 t:QL_DSP4_A2_DFFRE_32
select -assert-count 2 t:QL_DSP4_B2_DFFRE_18
write_verilog -noattr netlist.v
