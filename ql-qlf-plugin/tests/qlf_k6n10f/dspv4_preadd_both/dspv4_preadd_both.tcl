yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_both.v
hierarchy -top dspv4_preadd_both
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_both -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_both
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
# One pre-adder is the same count whichever of the two sums was taken, so the
# carries left behind are what say which. The 9-bit sum leaves about 9 and the
# 19-bit sum about 19, and the wider one is the one worth absorbing -- so a
# bound between them fails if the pass took the narrower side.
select -assert-max 12 t:adder_carry
