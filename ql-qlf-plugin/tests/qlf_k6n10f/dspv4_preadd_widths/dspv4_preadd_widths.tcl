# dspv4_preadd_widths -- (d + a) * b at every width the pre-adder accepts.
#
# Four shapes, one design, because all four fold. The A/B split is in the
# mode line asserted from tests/Makefile: counts cannot tell PREADD_A_MULT_B
# from PREADD_B_MULT_A, and which path a width lands on is the point here.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_widths.v
hierarchy -top dspv4_preadd_widths
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_widths -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_widths
check -assert
select -assert-count 4 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
select -assert-count 4 t:QL_DSP4_MULT
# Nothing left in fabric is what "the pre-adder folded" means.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
