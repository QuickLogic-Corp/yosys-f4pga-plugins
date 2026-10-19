# dspv4_preadd_regs -- the pre-adder shapes whose registers must be ABSORBED.
#
# Counts are totals over all four groups, which only works because every shape
# here asserts the same outcome. The shapes that must be REFUSED are separate
# tests on purpose: summed with these, a total could not tell a fold that
# happened from a refusal that happened in its place.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_regs.v
hierarchy -top dspv4_preadd_regs
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_regs -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_regs
check -assert
# Eleven shapes, every one of them folded.
select -assert-count 11 t:QL_DSP4_PREADD
select -assert-count 11 t:QL_DSP4_MULT
# No carry chain anywhere is what "the pre-adder survived" means.
select -assert-count 0 t:adder_carry
# Banks: 5 AD, 7 D, and the two operand registers the asym and enable shapes
# push onto A2. A1 stays empty -- the walk fills A2 first.
select -assert-count 5 t:QL_DSP4_AD_DFFR_32
select -assert-count 7 t:QL_DSP4_D_DFFRE_27
select -assert-count 2 t:QL_DSP4_A2_DFFRE_32
select -assert-count 0 t:QL_DSP4_A1_DFFRE_32
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
# The enable reached its bank rather than being tied off: a D bank with E tied
# to 1 is still a D_DFFRE_27, so the count above cannot tell the two apart.
select -assert-count 1 w:en0 %co:+\[E\] t:QL_DSP4_D_DFFRE_27 %i
# What stays in fabric: the outer stage of each 2-deep chain, and the B
# register evicted from the four-enable cell.
select -assert-count 64 t:sdffre
select -assert-count 0 t:dffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
