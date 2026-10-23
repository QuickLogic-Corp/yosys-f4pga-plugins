# dspv4_macc_c_refused_post_synth_sim -- three-input accumulator shapes that
# must NOT fold as MULT_ACC_C.
#
# Four designs, synthesised one at a time. Each asserts the mode by name from
# the pass's summary line and the outer add left in fabric, then sim/ runs
# every netlist against the RTL. A fold that should have been refused shows up
# here as the wrong mode name, or as a mismatch in the simulation.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_c_refused_post_synth_sim.v
design -save rtl

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

# A subtract with a C term: the inner subtract folds, the outer add stays.
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

# The first sum kept narrower than it is: the DSP takes a*b + c and the 36-bit
# cut, the outer add stays in fabric. Folding this gave 1967 of 2000 cycles
# wrong.
synth_one dspv4_macc_c_narrow_outer
assert_mode dspv4_macc_c_narrow_outer MULT_ADD_C
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 50 t:adder_carry
select -assert-count 50 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
write_syn dspv4_macc_c_narrow_outer

# The same cut on the inner spelling. wreduce narrows the feedback operand to
# the sum's 36 bits, so it no longer equals p's register and the fold never
# matches; p lands on the C port, copied into CREG, and s + c stays in fabric.
# That sum is 37 bits and p's upper bits are copies of its sign, so wreduce
# also trims p's register to 37 flops.
synth_one dspv4_macc_c_narrow_inner
assert_mode dspv4_macc_c_narrow_inner MULT_ADD_C
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 t:QL_DSP4_C_DFFRE_50
select -assert-count 37 t:adder_carry
select -assert-count 37 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
write_syn dspv4_macc_c_narrow_inner

# Each cell a refusal left in fabric is named with its reason, counted after
# the run: a cell that a later offer absorbed must not be named.
# outer_sub and outer_rsub each record both adders against this reason; only
# the one left in fabric counts, so each says 1, never 2.
if { [catch { exec grep -c {1 x  adder: accumulate with a subtract and a C term has no control word} synth.log } n] || $n != 2 } {
    error "expected the subtract line once in each of 2 modules, found $n"
}
if { ![catch { exec grep -c {2 x  adder: accumulate with a subtract} synth.log }] } {
    error "an adder absorbed by a later offer was counted as left in fabric"
}
if { [catch { exec grep -c {adder: the RTL cuts the first sum to 36 bits and reads above the cut} synth.log } n] || $n < 1 } {
    error "synth.log does not name: adder: the RTL cuts the first sum to 36 bits and reads above the cut"
}
