# dspv4_mult_regin_port -- an operand register that also drives a port is
# copied into the bank, not moved.
#
# One A2 bank in the DSP, and the 18 design flops still in fabric driving q.
# The walk from q to a flop is the assertion that fails on the bug: the walk
# saw one cell reader, moved the flop, and q was left undriven.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_regin_port.v
hierarchy -top dspv4_mult_regin_port
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_regin_port -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_regin_port
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# The register is in the A bank...
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
# ...and still in fabric for the port.
select -assert-count 18 t:sdffre
select -assert-any o:q %ci1 t:sdffre %i
