# dspv4_preadd_refused -- four shapes the pass must decline, four reasons.
#
# The multiply still lands in a DSP; only the addition stays soft. The
# surviving carry chains are the evidence -- counting $add proves nothing,
# it is lowered by this point either way.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_refused.v
hierarchy -top dspv4_preadd_refused
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_refused -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_refused
check -assert
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
# Five, not four: the 18x18 shape needs two DSPs.
select -assert-count 5 t:QL_DSP4_MULT
select -assert-min 1 t:adder_carry
