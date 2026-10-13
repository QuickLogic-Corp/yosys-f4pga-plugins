# dspv4_macc_c -- the three-input accumulator folds whole.
#
# p <= (a * b + p) + c is MULT_ACC_C: the product, the accumulator feedback
# and the C addend all inside one DSP. The assertions that matter are the
# negative ones -- no fabric adder and no fabric flop -- because the fallback
# the sibling tests exercise (MULT_ADD_C with the C adder outside) also
# passes a plain "one DSP was used" check.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_c.v
hierarchy -top dspv4_macc_c
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_c -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_c
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
# The accumulator is the DSP's own bank, not a copy of it on the C port.
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:QL_DSP4_C_DFFRE_50
# Nothing fell back to fabric.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:sdffre
select -assert-count 0 t:dffre
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
# And the output comes from that bank.
select -assert-any o:p %ci* t:QL_DSP4_ACC_DFFRE_64 %i
