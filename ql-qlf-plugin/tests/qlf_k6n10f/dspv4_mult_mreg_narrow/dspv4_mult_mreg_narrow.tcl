# dspv4_mult_mreg_narrow -- the M register is absorbed even when its D is a
# sign-extension of the product rather than the product signal itself.
#
# The pattern indexes on one bit and then checks the product occupies D's low
# bits; ql-dspv4.cc confirms the bits above it are sign padding. Absorbing the
# wider register is sound because the M bank and the ALU are 50 bits and
# sign-extend anyway, so sext(sext(Y,40),50) == sext(Y,50).
#
# Regression value: with an exact `===` index this silently absorbs nothing and
# the assertions below fail on the fabric flop, which is exactly how full gng
# behaved while the isolated module looked fine.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_mreg_narrow.v
hierarchy -top dspv4_mult_mreg_narrow
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_mreg_narrow -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_mreg_narrow
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 1 t:QL_DSP4_MV_DFFR_43
select -assert-count 1 t:QL_DSP4_MK_DFFR
select -assert-count 0 t:dffre
select -assert-count 0 t:dffnre
select -assert-count 0 t:dff
select -assert-count 0 t:dffn
