# dspv4_macc_c_order_post_synth_sim -- MULT_ACC_C folds whichever adder the
# accumulator feedback closes on.
#
# Four designs, synthesised one at a time. Each gets its structural assertions
# here, plus the mode asserted BY NAME from the pass's own summary line: the
# cell counts alone cannot tell MULT_ACC_C from MULT_ADD_C with the outer add
# left in fabric, and that is exactly the difference this test exists to pin.
# The netlists then run against the RTL in sim/.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_c_order_post_synth_sim.v
design -save rtl

# Synthesise one module and write its netlist under a _syn name for the
# testbench. The pass's log goes to synth.log so the mode can be read back.
proc synth_one {top} {
    global PASS_NAME LIB
    design -load rtl
    hierarchy -top $top
    tee -a synth.log $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $top
    check -assert
}
proc write_syn {top} {
    yosys cd
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}
# The last "modes inferred" line in synth.log belongs to the module just
# synthesised: the pass runs twice per flow, and the second run infers nothing
# and so prints no line.
proc assert_mode {top mode} {
    set f [open synth.log]
    set last ""
    foreach line [split [read $f] "\n"] {
        if { [string match "*modes inferred:*" $line] } { set last $line }
    }
    close $f
    if { $last ne "ql_dspv4: modes inferred: $mode x1" } {
        error "$top: expected $mode, the pass said: $last"
    }
}
file delete synth.log

# The feedback on the inner adder, as the pass always folded it.
synth_one dspv4_macc_c_inner
assert_mode dspv4_macc_c_inner MULT_ACC_C
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:QL_DSP4_C_DFFRE_50
select -assert-count 0 t:adder_carry
select -assert-count 0 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
write_syn dspv4_macc_c_inner

# The feedback on the outer adder: the same cell, nothing in fabric.
synth_one dspv4_macc_c_outer
assert_mode dspv4_macc_c_outer MULT_ACC_C
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:QL_DSP4_C_DFFRE_50
select -assert-count 0 t:adder_carry
select -assert-count 0 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
write_syn dspv4_macc_c_outer

# A subtract with a C term has no accumulating control word, so the inner
# subtract folds on its own and the outer add stays in fabric with p's
# register. Pinned so the refusal keeps landing on the same cell.
synth_one dspv4_macc_c_outer_sub
assert_mode dspv4_macc_c_outer_sub MULT_SUB_C
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_SUB
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 50 t:adder_carry
select -assert-count 50 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
write_syn dspv4_macc_c_outer_sub

synth_one dspv4_macc_c_outer_rsub
assert_mode dspv4_macc_c_outer_rsub MULT_RSUB_C
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_REV_SUB
select -assert-count 0 t:QL_DSP4_ALU_SUB
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 50 t:adder_carry
select -assert-count 50 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
write_syn dspv4_macc_c_outer_rsub
