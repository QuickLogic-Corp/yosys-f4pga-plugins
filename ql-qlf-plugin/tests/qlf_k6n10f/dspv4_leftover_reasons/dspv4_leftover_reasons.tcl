# dspv4_leftover_reasons -- every cell the DSP cannot take is named in the
# summary with the true reason, and only if it stayed in fabric.
#
# Ten shapes, synthesised one at a time so each line is checked on its own
# log. A refusal belongs to one offer; a later offer can still absorb the cell
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
