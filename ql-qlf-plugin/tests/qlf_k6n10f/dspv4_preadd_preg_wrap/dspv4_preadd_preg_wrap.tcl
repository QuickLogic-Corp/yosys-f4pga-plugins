# dspv4_preadd_preg_wrap -- the output register lands in the P bank even when
# the design has several multiplies.
#
# Two of the four instances register their result, so two P banks is the whole
# point: one of them used to be missed and its 33 bits sat in fabric while the
# log said every stage had been absorbed. Zero fabric flops is what tells a
# register that MOVED from one that was dropped.
#
# The mode name is asserted in tests/Makefile -- four PREADD_A_MULT_B cells look
# the same to a cell count whichever way the pre-adder went.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_preg_wrap.v
hierarchy -top dspv4_preadd_preg_wrap
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_preg_wrap -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_preg_wrap
check -assert
# One DSP per instance.
select -assert-count 4 t:QL_DSP4_PREADD
select -assert-count 4 t:QL_DSP4_MULT
# The two registered results are both in a P bank.
# Both result registers reach P. Without the containment filter on the
# output_flop index, wreduce leaves one of them a bit wider than the
# product and the exact compare misses it.
select -assert-count 2 t:QL_DSP4_ACC_DFFRE_64
# The two registered-input instances fill their operand banks.
# Nothing left outside.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
