# dspv4_preadd_adreg -- the pre-adder output register lands in the AD bank.
#
# Two assertions carry this test. QL_DSP4_AD_DFFR_32 proves the register went
# into the DSP rather than staying outside; adder_carry 0 proves the pre-adder
# was inferred at all, which is what the flop used to prevent by hiding the
# adder's output from the pattern.
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
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
# The AD register is inside the DSP...
select -assert-count 1 t:QL_DSP4_AD_DFFR_32
# ...and nothing is left in fabric: no stranded flop, no carry chain.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:dffre
select -assert-count 0 t:sdffre
