# dspv4_port_reg_post_synth_sim -- a register that also drives a module output
# is copied into the DSP bank, not moved.
#
# Four designs, synthesised one at a time. Each gets its structural assertions
# here, and the netlists then run against the RTL in sim/. The bug this pins
# left the output with no driver: `assign p = 50'hx`, which `check -assert`
# does not report and a cell count can only infer. The walk from the port back
# to a fabric flop is the structural assertion that fails on it; the
# simulation is the one that shows what it costs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_port_reg_post_synth_sim.v
design -save rtl

# Synthesise one module and write its netlist under a _syn name for the
# testbench. The pass's own log goes to synth.log so the copy can be asserted
# from what the pass said, not only from what it left behind.
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
file delete synth.log

# The baseline: p <= (a * b + p) + c folds whole as MULT_ACC_C. The negative
# assertions are the ones that matter -- the fallback the other three take
# also passes "one DSP was used".
synth_one dspv4_macc_c
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:QL_DSP4_C_DFFRE_50
select -assert-count 0 t:adder_carry
select -assert-count 0 t:sdffre
select -assert-count 0 t:dffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-any o:p %ci* t:QL_DSP4_ACC_DFFRE_64 %i
write_syn dspv4_macc_c

# A second reader of the inner sum: MULT_ACC_C is refused and the shape falls
# back to MULT_ADD_C with p on the C port. p's register is copied into CREG
# and kept in fabric for the port -- 50 flops for p, 50 for q.
synth_one dspv4_macc_c_reader
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 t:QL_DSP4_C_DFFRE_50
select -assert-count 50 t:adder_carry
select -assert-count 100 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-any o:p %ci1 t:sdffre %i
select -assert-any o:q %ci1 t:sdffre %i
write_syn dspv4_macc_c_reader

# The C adder reads the inner sum twice: refused by the double-read guard
# instead, same fallback, same requirement on p's register.
synth_one dspv4_macc_c_self
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 t:QL_DSP4_C_DFFRE_50
select -assert-count 50 t:adder_carry
select -assert-count 50 t:sdffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-any o:p %ci1 t:sdffre %i
write_syn dspv4_macc_c_self

# No accumulator at all: an A-operand register whose Q is also an output.
# One A2 bank in the DSP, and the 18 design flops still driving q.
synth_one dspv4_mult_regin_port
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
select -assert-count 18 t:sdffre
select -assert-count 0 t:\$mul
select -assert-any o:q %ci1 t:sdffre %i
write_syn dspv4_mult_regin_port

# The pass reported the three copies as copies. Each run logs its own summary
# line, so there are three of them and none for the baseline.
if { [catch { exec grep -c {shared operand register(s) copied into a bank} synth.log } copies] || $copies != 3 } {
    error "expected 3 copied-register summaries in synth.log, found: $copies"
}
