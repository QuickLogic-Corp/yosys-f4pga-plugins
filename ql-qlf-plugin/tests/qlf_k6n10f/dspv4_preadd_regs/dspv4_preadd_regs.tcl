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
# Fourteen shapes, every one of them folded.
select -assert-count 14 t:QL_DSP4_PREADD
select -assert-count 14 t:QL_DSP4_MULT
# No carry chain anywhere is what "the pre-adder survived" means.
select -assert-count 0 t:adder_carry
# Banks. D holds one stage and A two, so the six shapes whose two-deep chain
# arrived on D swap their operands: dr_p2, dr_p5, as_p, ce_p and ic_p put the
# chain in A1 and A2, and bs_p puts it in B1 and B2 on the B path. Without the
# swap D would hold 10, A1 none, and six outer stages would sit in fabric.
select -assert-count 5 t:QL_DSP4_AD_DFFR_32
select -assert-count 7 t:QL_DSP4_D_DFFRE_27
select -assert-count 5 t:QL_DSP4_A1_DFFRE_32
select -assert-count 6 t:QL_DSP4_A2_DFFRE_32
select -assert-count 1 t:QL_DSP4_B1_DFFRE_18
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
select -assert-count 2 t:QL_DSP4_ACC_DFFRE_64
# The enable reached its bank rather than being tied off: a D bank with E tied
# to 1 is still a D_DFFRE_27, so the count above cannot tell the two apart.
select -assert-count 1 w:en0 %co:+\[E\] t:QL_DSP4_D_DFFRE_27 %i
# The swapped chains took their enables with them: ce_d's onto both A stages,
# ce_a's onto D. Swapped without the enables, these would read the wrong pins.
select -assert-count 1 w:ce_en_d %co:+\[E\] t:QL_DSP4_A1_DFFRE_32 %i
select -assert-count 1 w:ce_en_d %co:+\[E\] t:QL_DSP4_A2_DFFRE_32 %i
select -assert-count 1 w:ce_en_a %co:+\[E\] t:QL_DSP4_D_DFFRE_27 %i
# ic_y's chain, not ic_x's, fills A1 and A2. Counted by register types alone,
# both orders score two stages and the RTL's order wins; ic_x's outer stage
# powers up at 5 and cannot go in, so only the swap takes all of ic_y.
select -assert-count 1 w:ic_y %co:+\[D\] t:QL_DSP4_A1_DFFRE_32 %i
# What stays in fabric: the B registers evicted from the two cells that want
# four enables (32), and ic_x's outer stage (16).
select -assert-count 48 t:sdffre
select -assert-count 0 t:dffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
