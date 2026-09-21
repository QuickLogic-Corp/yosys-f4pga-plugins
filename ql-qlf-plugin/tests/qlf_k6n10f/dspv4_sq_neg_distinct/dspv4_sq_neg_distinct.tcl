# dspv4_sq_neg_distinct -- the negated-product guard, Phase 4 / REQ-B3.
#
# Negative test. -(a * b) has no control word, so the pass must refuse the
# negate and let the matcher offer the plain multiply instead. What is being
# asserted is that the refusal is a FALLBACK and not a failure: the multiply
# still lands in a DSP, and only the negate stays soft.
#
# The assertion that matters is `QL_DSP4_ALU_SUB 0`. Emitting SQ_A_NEG here
# would route a to both multiplier ports and compute -(a * a) -- a netlist
# that synthesises, packs, routes and returns the wrong number, with b simply
# not connected to anything. Counting cells would not notice; only the leaf
# choice shows it.
#
# adder_carry is asserted PRESENT here, which is the opposite of every other
# dspv4 test. That is the point: the negate has to be somewhere, and if it is
# not in fabric and not in the ALU then it was dropped.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_sq_neg_distinct.v
hierarchy -top dspv4_sq_neg_distinct
$PASS_NAME -family qlf_k6n10f -top dspv4_sq_neg_distinct -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_sq_neg_distinct
check -assert
# The multiply still got its DSP -- the refusal cost the negate, not the DSP.
select -assert-count 1 t:QL_DSP4_MULT
# The ALU is NOT negating. This is the assertion the requirement turns on.
select -assert-count 0 t:QL_DSP4_ALU_SUB
select -assert-count 1 t:QL_DSP4_ALU_ADD
# Two distinct operands go straight to the multiplier ports, so nothing needs
# the pre-adder. A PREADD leaf here would mean the squaring path was taken.
select -assert-count 0 t:QL_DSP4_PREADD
# The negate is still in the design, in fabric, where it belongs.
select -assert-min 1 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$neg
