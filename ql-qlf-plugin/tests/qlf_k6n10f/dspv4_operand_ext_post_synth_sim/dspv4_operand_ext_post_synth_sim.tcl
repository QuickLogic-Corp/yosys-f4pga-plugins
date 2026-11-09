# dspv4_operand_ext_post_synth_sim -- an operand whose top bits repeat.
#
# Four designs, synthesised one at a time. Each asserts the mode and that the
# multiply is in the DSP; sim/ then runs the netlists against the RTL. The
# value check is the point: an unsigned operand that loses its repeated top
# bits still folds into the same cell, with the same leaves, and is wrong only
# when that bit is 1.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_operand_ext_post_synth_sim.v
design -save rtl

proc synth_one {top} {
    global PASS_NAME LIB
    design -load rtl
    hierarchy -top $top
    tee -q -o synth_$top.log $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $top
    check -assert
}
proc write_syn {top} {
    yosys cd
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}
proc log_has {top text} {
    set f [open synth_$top.log]
    set log [read $f]
    close $f
    if { [string first $text $log] < 0 } { error "$top: the log does not say: $text" }
}

foreach top {dspv4_operand_ext_ona dspv4_operand_ext_two dspv4_operand_ext_onb} {
    synth_one $top
    log_has $top "modes inferred: MULT x1"
    select -assert-count 1 t:QL_DSP4_MULT
    select -assert-count 0 t:\$mul
    select -assert-count 0 t:adder_carry
    write_syn $top
}

synth_one dspv4_operand_ext_ond
log_has dspv4_operand_ext_ond "modes inferred: PREADD_A_MULT_B x1"
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:adder_carry
write_syn dspv4_operand_ext_ond
