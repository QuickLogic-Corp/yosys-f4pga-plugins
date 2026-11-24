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
proc assert_kept {kept net_bits consumers reason {widened 0} {mixed 0}} {
    scratchpad -assert ql_dspv4_link_full_p.widened $widened
    scratchpad -assert ql_dspv4_link_full_p.kept $kept
    scratchpad -assert ql_dspv4_link_full_p.mixed $mixed
    if { [catch { exec grep -c -F $reason synth.log } n] || $n != $kept + $mixed } {
        error "expected [expr {$kept + $mixed}] line(s) with reason: $reason"
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
assert_kept 1 33 c:p_QL_DSP4_ALU_* {value range [1, 4294967296] does not fit 33 bits read signed}
write_syn dspv4_link_kept_top_edge

synth_one dspv4_link_kept_bottom_edge
assert_kept 1 33 c:p_QL_DSP4_ALU_* {value range [-4294967297, -2] does not fit 33 bits read signed}
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
assert_kept 1 36 c:p_QL_DSP4_ALU_* {carry-in (CIN) is not the constant its mode needs}
write_syn dspv4_link_kept_carry

# Seven consumers read 6 bits each; head -> rsub widens.
synth_one dspv4_link_kept_register_zeros
assert_kept 7 42 c:p?_QL_DSP4_ALU_* {does not fit 6 bits read signed} 1
write_syn dspv4_link_kept_register_zeros

synth_one dspv4_link_kept_preadd_b_short
assert_kept 1 46 c:p_QL_DSP4_ALU_* {value range [-35184372023296, 35184372088832] does not fit 46 bits read signed}
write_syn dspv4_link_kept_preadd_b_short

synth_one dspv4_link_kept_xpath_a_short
assert_kept 1 32 c:p_QL_DSP4_ALU_* {value range [-2147418112, 2147483648] does not fit 32 bits read signed}
write_syn dspv4_link_kept_xpath_a_short

synth_one dspv4_link_kept_xpath_b_short
assert_kept 1 36 c:p_QL_DSP4_ALU_* {value range [-34359476224, 34359738368] does not fit 36 bits read signed}
write_syn dspv4_link_kept_xpath_b_short

synth_one dspv4_link_kept_mixed
assert_kept 0 30 c:p_QL_DSP4_ALU_* {mixes P bits in place with other bits} 0 1
write_syn dspv4_link_kept_mixed

synth_one dspv4_link_kept_mixed_shift
assert_kept 0 32 c:p_QL_DSP4_ALU_* {mixes P bits in place with other bits} 0 1
write_syn dspv4_link_kept_mixed_shift

synth_one dspv4_link_kept_bcin
assert_kept 1 36 c:p_QL_DSP4_ALU_* {reads a cascade input (A_IN_SEL or B_IN_SEL)}
write_syn dspv4_link_kept_bcin

# Not simulated: with no CIN connection the RTL's carry-in is undriven, so it reads x.
synth_one dspv4_link_kept_no_cin
assert_kept 1 36 c:p_QL_DSP4_ALU_* {carry-in (CIN) is not the constant its mode needs}

# Not simulated: with AREG0 or BREG0 alone the techmap builds a register stage the sim model does not.
synth_one dspv4_link_kept_first_stage_registers
assert_kept 2 12 c:p?_QL_DSP4_ALU_* {value range [-40, -5] does not fit 6 bits read signed}
