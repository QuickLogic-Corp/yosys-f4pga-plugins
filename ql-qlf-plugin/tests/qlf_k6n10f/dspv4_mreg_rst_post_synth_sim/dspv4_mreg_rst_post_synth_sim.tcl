# dspv4_mreg_rst_post_synth_sim -- an M register and an operand register on
# different resets. The M register goes in; the operand register stays out.
#
# Two designs, synthesised one at a time. Each asserts the mode, the M bank and
# its reset, the operand register left in fabric, and the reason the pass gives
# for it. sim/ then runs both netlists against the RTL with both resets pulsed:
# leaving the M register out instead would compute a cycle early, which no
# cell count shows.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mreg_rst_post_synth_sim.v
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
# Each module gets its own log. The pass runs twice per flow; the second run
# infers nothing and prints no mode line, so the line found is this module's.
proc assert_log {top text} {
    set f [open synth_$top.log]
    set log [read $f]
    close $f
    if { [string first $text $log] < 0 } {
        error "$top: the log does not say: $text"
    }
}

# M between the multiply and the adder.
synth_one dspv4_mreg_rst_add
assert_log dspv4_mreg_rst_add "modes inferred: MULT_ADD_C x1"
assert_log dspv4_mreg_rst_add "x  clock/reset/enable disagree with the rest of the cell"
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_M_DFFR_50 %i
select -assert-count 0 t:QL_DSP4_A2_DFFRE_32
select -assert-count 0 t:QL_DSP4_B2_DFFRE_18
select -assert-count 16 t:sdffre
select -assert-count 0 t:adder_carry
write_syn dspv4_mreg_rst_add

# A product register, then a result register: the first takes the M bank and
# the second the P bank.
synth_one dspv4_mreg_rst_out
assert_log dspv4_mreg_rst_out "modes inferred: MULT x1"
assert_log dspv4_mreg_rst_out "x  clock/reset/enable disagree with the rest of the cell"
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_M_DFFR_50 %i
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:QL_DSP4_A2_DFFRE_32
select -assert-count 0 t:QL_DSP4_B2_DFFRE_18
select -assert-count 16 t:sdffre
write_syn dspv4_mreg_rst_out
