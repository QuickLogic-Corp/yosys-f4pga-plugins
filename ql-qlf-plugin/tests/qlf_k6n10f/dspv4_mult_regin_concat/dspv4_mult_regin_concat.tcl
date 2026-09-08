# dspv4_mult_regin_concat -- an operand built from two registers must still be
# absorbed into the DSP's A bank.
#
# The assertion with teeth is QL_DSP4_A2_DFFRE_32: before the per-bit register
# walk this count was 0 while B2 absorbed fine, because the {hir, lor} operand
# matched no single flop's whole Q. Asserting the DSP alone would pass either way.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_regin_concat.v
hierarchy -top dspv4_mult_regin_concat
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_regin_concat -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_regin_concat
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# The two-register operand was absorbed into the A bank ...
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
# ... and the single-register operand into the B bank, as it always did.
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
# Nothing was left behind in fabric: all three input registers moved in, and the
# output register became the accumulator bank.
select -assert-count 0 t:sdffre
select -assert-count 0 t:dffre
