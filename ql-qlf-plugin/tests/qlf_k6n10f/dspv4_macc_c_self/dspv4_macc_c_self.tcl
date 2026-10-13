# dspv4_macc_c_self -- the double-read refusal lands in the same fallback.
#
# p <= s + s reads the inner sum on both operands of the C adder. That is
# refused by the double-read guard rather than the fan-out guard, but the
# fallback is the same MULT_ADD_C with p on the C port, and p's register has
# to be copied, not moved: p is a module output.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_c_self.v
hierarchy -top dspv4_macc_c_self
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_c_self -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_c_self
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 50 t:adder_carry
select -assert-count 1 t:QL_DSP4_C_DFFRE_50
# The 50 flops of p survive the copy, and p is driven by them.
select -assert-count 50 t:sdffre
select -assert-any o:p %ci1 t:sdffre %i
