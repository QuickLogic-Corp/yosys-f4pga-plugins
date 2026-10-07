# dspv4_preadd_adreg -- the pre-adder's output register lands in the AD bank.
#
# Three assertions carry this test. QL_DSP4_AD_DFFR_32 proves the register went
# into the DSP; zero fabric flops prove it was MOVED rather than dropped, which
# a cell count on its own cannot tell apart; adder_carry 0 proves the pre-adder
# was inferred at all, which is what the flop used to prevent by hiding the
# adder's output from the pattern.
#
# The inferred modes are asserted by name in tests/Makefile -- counts cannot
# tell PREADD_A_MULT_B from PREADD_B_MULT_A, and the two paths are separate
# matches in the pattern, so both need naming.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_adreg.v
hierarchy -top dspv4_preadd_adreg
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_adreg
check -assert
# One block per path.
select -assert-count 2 t:QL_DSP4_PREADD
select -assert-count 2 t:QL_DSP4_MULT
# Both AD registers are inside the DSP...
select -assert-count 2 t:QL_DSP4_AD_DFFR_32
# ...and the D bank is untouched, because D itself is not registered here.
select -assert-count 0 t:QL_DSP4_D_DFFRE_27
# ...and nothing is left outside: no stranded flop, no carry chain.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:dffre
select -assert-count 0 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
