# dspv4_mult_regout2 -- both output register stages are absorbed.
#
# One stage lands in the M bank and one in the ACC/P bank, so no flop is left in
# fabric. Asserting zero fabric flops is the assertion with teeth: absorbing only
# the first stage still produces a working netlist, just a worse one, and that is
# what the pass did before MREG inference.
#
# Note this exercises MREG with PREG on a plain multiply, which is the one
# combination where dsp4_logical_map.v's ALU_MULT_ONLY fold is allowed to apply
# to a lone MREG -- it must NOT apply here, because both registers were asked
# for. Getting that wrong collapses two stages into one and drops a cycle.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_regout2.v
hierarchy -top dspv4_mult_regout2
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_regout2 -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_regout2
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# Both stages inside: the M bank and the accumulator bank.
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 1 t:QL_DSP4_MV_DFFR_43
select -assert-count 1 t:QL_DSP4_MK_DFFR
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
# Nothing left in fabric.
select -assert-count 0 t:dffre
select -assert-count 0 t:dffnre
select -assert-count 0 t:dff
select -assert-count 0 t:dffn
