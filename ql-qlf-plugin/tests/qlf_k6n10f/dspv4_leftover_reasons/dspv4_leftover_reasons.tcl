# dspv4_leftover_reasons -- every cell the DSP cannot take is named in the
# summary with the true reason, and only if it stayed in fabric.
#
# Ten shapes and one twelve-block design, synthesised one at a time so each
# line is checked on its own log. A refusal belongs to one offer; a later offer can still absorb the cell
# it named, so each shape asserts both the cells left and the line.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_leftover_reasons.v
design -save rtl

proc synth_one {top {prep ""}} {
    global PASS_NAME LIB
    design -load rtl
    hierarchy -top $top
    if { $prep ne "" } { eval $prep }
    tee -q -o synth_$top.log $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $top
    check -assert
}
proc log_has {top text} {
    set f [open synth_$top.log]
    set log [read $f]
    close $f
    if { [string first $text $log] < 0 } { error "$top: the log does not say: $text" }
}
proc log_lacks {top text} {
    set f [open synth_$top.log]
    set log [read $f]
    close $f
    if { [string first $text $log] >= 0 } { error "$top: the log should not say: $text" }
}

synth_one k2s
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 64 t:sdffre
log_has k2s "1 x  its output is marked keep"
log_lacks k2s "the DSP has no register stage after P"

synth_one mk
select -assert-count 35 t:adder_carry
select -assert-count 32 t:sdffre
log_has mk "1 x  adder: it reads an M register that cannot go in: it carries keep or a non-zero init"
log_has mk "1 x  it carries keep or a non-zero init"

synth_one mz
select -assert-count 35 t:adder_carry
select -assert-count 32 t:sdffre
log_has mz "1 x  adder: it reads an M register that cannot go in: it resets to a non-zero value, and the bank resets to zero"
log_has mz "1 x  it resets to a non-zero value, and the bank resets to zero"

# The cell keeps M and the adder and gives up the result register: only that
# register may be named, and not as "not offered".
synth_one mc
log_has mc "modes inferred: MULT_ADD_C x1"
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 0 t:adder_carry
select -assert-count 35 t:sdffre
log_has mc "1 x  its clock differs from the M register's"
log_lacks mc "adder: "
log_lacks mc "the pattern did not offer it"

synth_one mp
select -assert-count 35 t:adder_carry
select -assert-count 33 t:sdffre
log_has mp "1 x  adder: it reads an M register that cannot go in: the bits above the product are not a sign extension of it"
log_has mp "1 x  the bits above the product are not a sign extension of it"
log_lacks mp "the pattern did not offer it"

synth_one ap
select -assert-count 35 t:adder_carry
log_has ap "1 x  adder: it reads the product padded with something other than its sign"

synth_one fk
log_has fk "modes inferred: MULT_ADD_C x1"
select -assert-count 50 t:adder_carry
log_has fk "1 x  adder: the first sum it reads is marked keep"

synth_one rk
select -assert-count 32 t:sdffre
log_has rk "1 x  the value it registers is marked keep"
log_lacks rk "the pattern did not offer it"

synth_one ck {yosys proc; yosys setattr -set keep 1 t:\$add}
select -assert-count 35 t:adder_carry
log_has ck "1 x  adder: it is marked keep"

synth_one pd
log_has pd "modes inferred: MULT_SUB_C x1"
select -assert-count 17 t:adder_carry
log_has pd "1 x  pre-adder: no control word for it with this ALU direction"

# preadd_regs_refused -- twelve pre-adder register refusals in one design.
# Counts are totals over the twelve blocks. The log checks name each
# refusal, so a block that starts folding cannot hide behind another that
# stops.
synth_one preadd_regs_refused
# Every block still multiplies in a DSP.
select -assert-count 12 t:QL_DSP4_MULT
# en, re, nz, as, ck, ki and np keep their pre-adder in fabric, 17 carries each.
# mr folds its pre-adder but not its final 34-bit add. sub, wd and me fold
# theirs.
select -assert-count 3 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_PRESUB
select -assert-count 153 t:adder_carry
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
select -assert-count 4 t:QL_DSP4_A2_DFFRE_32
select -assert-count 1 w:en_en %co:+\[E\] t:QL_DSP4_A2_DFFRE_32 %i
select -assert-count 1 w:re_en %co:+\[E\] t:QL_DSP4_A2_DFFRE_32 %i
# ki's B register is in its cell's B bank: the AD offers that gave it up were
# refused, and the plain multiply that folded kept it.
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
# sub, wd and me keep their chain on D: one stage in, the outer one outside.
select -assert-count 3 t:QL_DSP4_D_DFFRE_27
select -assert-count 1 w:me_en1 %co:+\[E\] t:QL_DSP4_D_DFFRE_27 %i
select -assert-count 0 t:QL_DSP4_A1_DFFRE_32
# Fabric flops: nz (17, resets to 5), the outer stages of sub, wd and me
# (16 each), ck's B register (16), ki's AD register (17, powers up at 1),
# np's AD and result registers (17 and 33, reset to 5 and 7), sp's result
# register (32, reset to 7), and as (17, async reset). sp's operand register
# goes to A2, one of the four above.
select -assert-count 180 t:sdffre
select -assert-count 17 t:dffre
# Each refusal by its own reason, so one block that starts folding cannot
# hide behind another that stops.
log_has preadd_regs_refused "modes inferred: MULT x8, PREADD_A_MULT_B x3, PREADD_A_SUB_B x1"
log_has preadd_regs_refused "2 x  pre-adder output register has a clock enable, which the AD bank does not have"
log_has preadd_regs_refused "x  pre-adder output register cannot go in the AD bank: it resets to a non-zero value"
# mr's AD register does go in the AD bank -- the offer with M was refused, the
# one without M folded -- so its refusal must not reach the summary.
log_lacks preadd_regs_refused "cannot go in the AD bank: the M register resets differently"
# np's and sp's result registers stay out for their own reset values, not for
# an AD register the cell never took.
log_has preadd_regs_refused "2 x  it resets to a non-zero value, and the P bank resets to zero"
log_lacks preadd_regs_refused "the cell took a pre-adder output register instead"
# Summary lines come from the folds that happened, not from refused offers:
# sp's refused offer stalled its operand chain, and the walk counts are
# the winning folds' own.
log_lacks preadd_regs_refused "clock/reset/enable disagree with the rest of the cell"
log_has preadd_regs_refused "walks that ended with nothing left to take (not stalls): 15 with no register on the operand, 6 having absorbed every stage present"
log_has preadd_regs_refused "x  pre-adder output register cannot go in the AD bank: its clock differs from the rest of the cell"
log_has preadd_regs_refused "x  pre-adder output register cannot go in the AD bank: it carries keep or a non-zero init"
log_has preadd_regs_refused "x  driver is an async-reset flop"
log_has preadd_regs_refused "x  a subtract cannot swap its two-deep register chain off D"
log_has preadd_regs_refused "x  the two-deep register chain stays on D: the other operand does not fit the port it would move to"
# ck's cell gives up its B chain for the other clock, and says so. ki's AD
# offers gave up a chain and were then refused, so no eviction line may appear.
log_has preadd_regs_refused "1 x  B register chain given up: its clock or reset differs from the A chain"
log_lacks preadd_regs_refused "resets differently from the AD register"
