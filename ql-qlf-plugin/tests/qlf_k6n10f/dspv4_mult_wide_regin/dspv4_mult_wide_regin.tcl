# dspv4_mult_wide_regin -- operand register absorption on a SPLIT multiply.
#
# Without the fix this test fails on the B banks: they come out 0 because the
# split cuts b2 in half and neither DSP uses the whole register.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_wide_regin.v
hierarchy -top dspv4_mult_wide_regin
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_wide_regin -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_wide_regin
check -assert

# 32x32 does not fit one DSP, so it becomes two.
select -assert-count 2 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul

# A is taken whole by both DSPs, so each gets its own copy of both stages.
select -assert-count 2 t:QL_DSP4_A1_DFFRE_32
select -assert-count 2 t:QL_DSP4_A2_DFFRE_32

# B is cut in half, and each DSP registers its own half. This is what the fix
# added -- these four were 0 before it.
select -assert-count 2 t:QL_DSP4_B1_DFFRE_18
select -assert-count 2 t:QL_DSP4_B2_DFFRE_18

# All four design registers moved inside, so none is left in fabric.
select -assert-count 0 t:dffre
select -assert-count 0 t:sdffre
