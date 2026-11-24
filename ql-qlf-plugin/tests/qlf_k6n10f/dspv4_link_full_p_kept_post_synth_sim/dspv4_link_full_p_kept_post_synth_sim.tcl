# C links that ql_dspv4_link_full_p must leave as they are.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog -lib $LIB/qlf_k6n10f/QL_DSP4.v
read_verilog dspv4_link_full_p_kept_post_synth_sim.v
design -save rtl

proc synth_one {top} {
    global PASS_NAME LIB
    design -load rtl
    hierarchy -top $top
    file delete synth.log
    tee -o synth.log $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $top
    check -assert
}
# Counts bits after splitnets on the consumers only: an accumulator's own Z reads all 64.
proc assert_kept {kept net_bits consumers reason} {
    scratchpad -assert ql_dspv4_link_full_p.widened 0
    scratchpad -assert ql_dspv4_link_full_p.kept $kept
    if { [catch { exec grep -c -F $reason synth.log } n] || $n != $kept } {
        error "expected $kept kept link(s) with reason: $reason"
    }
    design -save syn
    splitnets -ports
    select -assert-count $net_bits t:QL_DSP4* %co w:* %i $consumers %ci:+\[Z\] w:* %i %i
    design -load syn
}
proc write_syn {top} {
    yosys cd
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}

synth_one dspv4_link_kept_trunc
assert_kept 1 30 c:p_QL_DSP4_ALU_* {value range [-17179738112, 17179869184] does not fit 30 bits read signed}
write_syn dspv4_link_kept_trunc

synth_one dspv4_link_kept_wrap
assert_kept 1 36 c:p_QL_DSP4_ALU_* {value range [-51539476480, 51539607551] does not fit 36 bits read signed}
write_syn dspv4_link_kept_wrap

synth_one dspv4_link_kept_zext
assert_kept 1 36 c:p_QL_DSP4_ALU_* {value range [-17179738112, 17179869184] does not fit 36 bits read unsigned}
write_syn dspv4_link_kept_zext

synth_one dspv4_link_kept_acc
assert_kept 1 36 c:p_QL_DSP4_ALU_* {mode is MULT_ACC, which has no value range rule here}
write_syn dspv4_link_kept_acc

synth_one dspv4_link_kept_preadd
assert_kept 1 36 c:p_QL_DSP4_ALU_* {value range [-34359476224, 34359738368] does not fit 36 bits read signed}
write_syn dspv4_link_kept_preadd

synth_one dspv4_link_kept_reset
assert_kept 1 14 c:p_QL_DSP4_ALU_* {value range [-8, 3124] does not fit 14 bits read unsigned}
write_syn dspv4_link_kept_reset

# One DSP reads the other's 40 bits; the other reads its own C register's 50.
synth_one dspv4_link_kept_loop
assert_kept 2 90 t:QL_DSP4_ALU_* {value range [-566935552000, 566935683071] does not fit 40 bits read signed}
write_syn dspv4_link_kept_loop

synth_one dspv4_link_kept_top_edge
assert_kept 1 33 c:p_QL_DSP4_ALU_* {value range [0, 4294967296] does not fit 33 bits read signed}
write_syn dspv4_link_kept_top_edge

synth_one dspv4_link_kept_bottom_edge
assert_kept 1 33 c:p_QL_DSP4_ALU_* {value range [-4294967297, 0] does not fit 33 bits read signed}
write_syn dspv4_link_kept_bottom_edge

synth_one dspv4_link_kept_exceed
assert_kept 1 49 c:p_QL_DSP4_ALU_* {value can exceed the 50-bit P port}
write_syn dspv4_link_kept_exceed

synth_one dspv4_link_kept_rss
assert_kept 1 36 c:p_QL_DSP4_ALU_* {rounds or shifts P (USE_RSS)}
write_syn dspv4_link_kept_rss

# The techmap does not lower A_IN_SEL, so the source stays a QL_DSP4 cell.
synth_one dspv4_link_kept_acin
assert_kept 1 36 c:p_QL_DSP4_ALU_* {reads a cascade input (A_IN_SEL or B_IN_SEL)}
write_syn dspv4_link_kept_acin

synth_one dspv4_link_kept_carry
assert_kept 1 36 c:p_QL_DSP4_ALU_* {carry-in is not the one its mode ties}
write_syn dspv4_link_kept_carry
