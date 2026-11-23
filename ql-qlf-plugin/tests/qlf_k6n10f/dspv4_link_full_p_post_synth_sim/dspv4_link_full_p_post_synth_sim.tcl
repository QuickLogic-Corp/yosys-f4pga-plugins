# C links that ql_dspv4_link_full_p must widen to the source's full P (aurora2 #2870).
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_link_full_p_post_synth_sim.v
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
# The last line: ql_dspv4's second run infers nothing and prints none.
proc assert_modes {top modes} {
    set f [open synth.log]
    set last ""
    foreach line [split [read $f] "\n"] {
        if { [string match "*modes inferred:*" $line] } { set last $line }
    }
    close $f
    if { $last ne "ql_dspv4: modes inferred: $modes" } {
        error "$top: expected $modes, the pass said: $last"
    }
}
# The net and the P bits above it are one wire, so count bits after splitnets.
proc assert_links {widened} {
    scratchpad -assert ql_dspv4_link_full_p.widened $widened
    scratchpad -assert ql_dspv4_link_full_p.kept 0
    design -save syn
    splitnets -ports
    select -assert-count [expr {50 * $widened}] t:QL_DSP4_* %co w:* %i t:QL_DSP4_ALU_* %ci:+\[Z\] w:* %i %i
    design -load syn
}
proc write_syn {top} {
    yosys cd
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}

# design, modes ql_dspv4 infers, links widened
set blocks {
    {dspv4_link_small               {MULT_ADD_C x1, MULT x1}                                  1}
    {dspv4_link_chain               {MULT_ADD_C x3, MULT x1}                                  3}
    {dspv4_link_chain_reversed      {MULT_ADD_C x3, MULT x1}                                  3}
    {dspv4_link_registered          {MULT_ADD_C x2, MULT x1}                                  2}
    {dspv4_link_sub                 {MULT x2, MULT_SUB_C x1, MULT_RSUB_C x1}                  2}
    {dspv4_link_zero                {MULT_ADD_C x1, MULT x1}                                  1}
    {dspv4_link_preadd_a            {PREADD_A_MULT_B x1, MULT_ADD_C x1}                       1}
    {dspv4_link_preadd_a_sub        {PREADD_A_SUB_B x1, MULT_ADD_C x1}                        1}
    {dspv4_link_preadd_b            {PREADD_B_MULT_A x1, MULT_ADD_C x1}                       1}
    {dspv4_link_preadd_b_sub        {PREADD_B_SUB_A x1, MULT_ADD_C x1}                        1}
    {dspv4_link_preadd_a_chain      {PREADD_A_MULT_B_C x1, PREADD_A_MULT_B x1, MULT_ADD_C x1} 2}
    {dspv4_link_preadd_a_sub_chain  {PREADD_A_SUB_B_C x1, PREADD_A_SUB_B x1, MULT_ADD_C x1}   2}
    {dspv4_link_preadd_b_chain      {PREADD_B_MULT_A_C x1, PREADD_B_MULT_A x1, MULT_ADD_C x1} 2}
    {dspv4_link_preadd_b_sub_chain  {PREADD_B_SUB_A_C x1, PREADD_B_SUB_A x1, MULT_ADD_C x1}   2}
}
foreach block $blocks {
    lassign $block top modes widened
    synth_one $top
    assert_modes $top $modes
    assert_links $widened
    write_syn $top
}
