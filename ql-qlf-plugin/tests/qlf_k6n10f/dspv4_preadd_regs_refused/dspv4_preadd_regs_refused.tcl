# dspv4_preadd_regs_refused -- pre-adder registers the DSP must NOT absorb.
#
# Counts are totals over nine blocks that all assert a refusal. The log
# assertions in tests/Makefile name each refusal, so a block that starts
# folding cannot hide behind another that stops.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_regs_refused.v
hierarchy -top dspv4_preadd_regs_refused
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_regs_refused -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_regs_refused
check -assert
# Every block still multiplies in a DSP.
select -assert-count 9 t:QL_DSP4_MULT
# en, re, nz, as and ck keep their pre-adder in fabric, 17 carries each. mr
# folds its pre-adder but not its final 34-bit add. sub, wd and me fold theirs.
select -assert-count 3 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 119 t:adder_carry
# Only mr fills an AD bank, and then without its M register: the two reset
# differently and both take RSTN. Its product register goes to P instead,
# whose ACCRSTN is a pin of its own.
select -assert-count 1 t:QL_DSP4_AD_DFFR_32
select -assert-count 0 t:QL_DSP4_M_DFFR_50
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_AD_DFFR_32 %i
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_ACC_DFFRE_64 %i
# en and re's registers have an enable, so they land in A2 as ordinary
# operand registers, with the enable on CEA. ck's lands there too, once the
# cell gives up the B register on the other clock.
select -assert-count 3 t:QL_DSP4_A2_DFFRE_32
select -assert-count 1 w:en_en %co:+\[E\] t:QL_DSP4_A2_DFFRE_32 %i
select -assert-count 1 w:re_en %co:+\[E\] t:QL_DSP4_A2_DFFRE_32 %i
# sub, wd and me keep their chain on D: one stage in, the outer one outside.
select -assert-count 3 t:QL_DSP4_D_DFFRE_27
select -assert-count 1 w:me_en1 %co:+\[E\] t:QL_DSP4_D_DFFRE_27 %i
select -assert-count 0 t:QL_DSP4_A1_DFFRE_32
# Fabric flops: nz (17, resets to 5), the outer stages of sub, wd and me
# (16 each), ck's B register (16), and as (17, async reset).
select -assert-count 81 t:sdffre
select -assert-count 17 t:dffre
