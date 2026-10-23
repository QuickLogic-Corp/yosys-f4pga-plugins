# dspv4_preg_rst_post_synth_sim -- operand registers and the result register on
# different resets. All go in: operand banks on RSTN, the P bank on ACCRSTN.
#
# Three designs, synthesised one at a time. Each asserts the mode, every bank,
# and which reset net reaches which bank; sim/ then runs the netlists against
# the RTL with both resets pulsed.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preg_rst_post_synth_sim.v
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

synth_one dspv4_preg_rst_mul
log_has dspv4_preg_rst_mul "modes inferred: MULT x1"
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_A2_DFFRE_32 %i
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_B2_DFFRE_18 %i
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_ACC_DFFRE_64 %i
select -assert-count 0 t:sdffre
write_syn dspv4_preg_rst_mul

synth_one dspv4_preg_rst_acc
log_has dspv4_preg_rst_acc "modes inferred: MULT_ACC x1"
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_A2_DFFRE_32 %i
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_ACC_DFFRE_64 %i
select -assert-count 0 t:sdffre
write_syn dspv4_preg_rst_acc

synth_one dspv4_preg_rst_addc
log_has dspv4_preg_rst_addc "modes inferred: MULT_ADD_C x1"
select -assert-count 1 t:QL_DSP4_C_DFFRE_50
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_C_DFFRE_50 %i
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_ACC_DFFRE_64 %i
select -assert-count 0 t:sdffre
write_syn dspv4_preg_rst_addc
