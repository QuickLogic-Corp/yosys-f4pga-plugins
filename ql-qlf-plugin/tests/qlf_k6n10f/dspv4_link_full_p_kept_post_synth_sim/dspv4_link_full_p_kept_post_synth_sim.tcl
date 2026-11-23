# dspv4_link_full_p_kept_post_synth_sim -- C links that ql_dspv4_link_full_p
# must leave as they are (aurora2 #2870).
#
# Reading the source's full P is only the same value when the source's value
# always fits the RTL net. In each design here it does not, or no rule says
# what range the source's mode can reach.
#
# Each design is synthesised alone. Per design we assert:
#   - the pass kept one link and widened none (scratchpad);
#   - the reason it printed;
#   - the distinct DSP-driven bits the consumer's Z port reads: only the RTL
#     net's bits, never the source's P bits above them. The consumer is the
#     ALU that computes p (synth_ql names an ALU after the net it drives).
#     Only the consumer: the accumulator's own Z reads all 64 of its bits.
# Then sim/ runs every netlist against the RTL. A link widened by mistake
# shows up there as wrong values.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

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
# After synth_ql the RTL net and the P bits above it are one wire, so the
# bits are counted on a copy with every bit split into its own wire.
proc assert_kept {net_bits reason} {
    scratchpad -assert ql_dspv4_link_full_p.widened 0
    scratchpad -assert ql_dspv4_link_full_p.kept 1
    if { [catch { exec grep -c -F $reason synth.log } n] || $n != 1 } {
        error "expected one kept link with reason: $reason"
    }
    design -save syn
    splitnets -ports
    select -assert-count $net_bits t:QL_DSP4_* %co w:* %i c:p_QL_DSP4_ALU_* %ci:+\[Z\] w:* %i %i
    design -load syn
}
proc write_syn {top} {
    yosys cd
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}

synth_one dspv4_link_kept_trunc
assert_kept 30 {value range [-17179738112, 17179869184] does not fit 30 bits read signed}
write_syn dspv4_link_kept_trunc

synth_one dspv4_link_kept_wrap
assert_kept 36 {value range [-51539476480, 51539607551] does not fit 36 bits read signed}
write_syn dspv4_link_kept_wrap

synth_one dspv4_link_kept_zext
assert_kept 36 {value range [-17179738112, 17179869184] does not fit 36 bits read unsigned}
write_syn dspv4_link_kept_zext

synth_one dspv4_link_kept_acc
assert_kept 36 {mode is MULT_ACC, which has no value range rule here}
write_syn dspv4_link_kept_acc

synth_one dspv4_link_kept_preadd
assert_kept 36 {value range [-34359476224, 34359738368] does not fit 36 bits read signed}
write_syn dspv4_link_kept_preadd
