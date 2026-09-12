# dspv4_mult_mreg -- a register between multiply and adder lands in the M bank.
#
# Two things are asserted. The M banks exist, which is what MREG inference is
# for: QL_DSP4_M_DFFR_50 plus MV_DFFR_43 and MK_DFFR, because the M stage
# registers all three multiplier outputs in lockstep. And no flop is left in
# fabric, because a lone MREG on a DSP whose ALU takes C must NOT be folded onto
# P -- that fold reschedules C by a cycle. dsp4_logical_map.v gates it on
# ALU_MULT_ONLY for exactly this case.
#
# The adder fusing at the same time is the point of the feature: with the
# register in fabric the $mul -> $add match cannot reach the adder either, so
# this shape used to cost a flop AND a fabric adder.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_mreg.v
hierarchy -top dspv4_mult_mreg
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_mreg -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_mreg
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# The M stage, not the P register.
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 1 t:QL_DSP4_MV_DFFR_43
select -assert-count 1 t:QL_DSP4_MK_DFFR
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
# Nothing left behind.
select -assert-count 0 t:dffre
select -assert-count 0 t:dffnre
select -assert-count 0 t:dff
select -assert-count 0 t:dffn
select -assert-count 0 t:adder_carry
