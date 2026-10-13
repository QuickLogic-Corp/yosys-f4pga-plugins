# dspv4_macc_c_reader -- refusing MULT_ACC_C must not strand the accumulator.
#
# The inner sum has a second reader, so the pass declines to absorb the C
# adder and falls back to MULT_ADD_C with p on the C port. p's register is
# copied into CREG and ALSO kept in fabric, because p is a module output and
# the bank cannot drive a port. The walk from p back to a fabric flop is the
# assertion that fails on the bug: the flop was moved into the bank and p was
# left with no driver, which `check -assert` does not report.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_c_reader.v
hierarchy -top dspv4_macc_c_reader
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_c_reader -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_c_reader
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
# The refusal: no accumulator bank, and the `+ c` adder stayed in fabric.
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 50 t:adder_carry
# p's register went into CREG as a copy...
select -assert-count 1 t:QL_DSP4_C_DFFRE_50
# ...and the original is still standing, 50 flops for p and 50 for q.
select -assert-count 100 t:sdffre
# Both outputs are driven from fabric flops. Without the copy p has no driver.
select -assert-any o:p %ci1 t:sdffre %i
select -assert-any o:q %ci1 t:sdffre %i
