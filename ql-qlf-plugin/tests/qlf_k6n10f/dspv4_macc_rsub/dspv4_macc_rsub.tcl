# dspv4_macc_rsub -- a*b - out stays soft until CIN can be driven.
#
# The reverse-subtract direction is only correct at CIN=1, and the pass never
# drives CIN. Refusing is the right answer; mapping it would be off by one. This
# test pins the refusal so that wiring CIN later has to update it deliberately.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_rsub.v
hierarchy -top dspv4_macc_rsub
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_rsub -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_rsub
# The multiply still goes into a DSP; only the accumulate stays outside.
select -assert-count 1 t:QL_DSP4_MULT
# No reverse-subtract leaf was emitted.
select -assert-count 0 t:QL_DSP4_ALU_REV_SUB
# The accumulator is in fabric, not in the DSP's bank -- asserted positively so
# the test pins the refusal rather than merely the absence of a bank.
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 36 t:adder_carry
select -assert-count 36 t:sdffre
