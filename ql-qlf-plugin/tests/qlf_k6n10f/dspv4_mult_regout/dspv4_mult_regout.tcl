# dspv4_mult_regout -- a pipeline register on the product is absorbed.
#
# The DSP's P register can hold this, so a correct result leaves no flop in
# fabric at all. That is the assertion with teeth: leaving the register outside
# is not a wrong answer, it is a QoR cliff, and it was enough to make the
# register-heavy cascade_* designs fail to route -- 218 flop bits in fabric for
# one design instead of 74.
#
# The reset is active-low, which is the pass-through case for ARSTN. The
# active-high case inverts, and verify_inference.py covers that one by value.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_regout.v
hierarchy -top dspv4_mult_regout
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_regout -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_regout
check -assert
# The product reached a DSP and the register went with it.
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:dffre
select -assert-count 0 t:dffnre
select -assert-count 0 t:dff
select -assert-count 0 t:dffn
