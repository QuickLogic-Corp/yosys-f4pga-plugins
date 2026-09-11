# dspv4_mult_add_evencoef -- a sum of products with a coefficient wreduce splits.
#
# Regression test. wreduce rewrites `x * c`, for a constant c with k low zero
# bits, as `(x * (c >> k)) << k`. The `add` match tolerates sign padding ABOVE
# the product but nothing below it, so the adder was never offered as a
# candidate at all and nothing was logged -- the multiply came out as a bare
# MULT and the adder stayed in fabric.
#
# On the last term of a left-associative sum that costs two things, and both are
# asserted below: the outermost adder, which no other product's DSP can take,
# and the output register that adder's DSP would have held in P.
#
# dsp_filter_matrix's direct-form FIR is this shape with four taps. FD_C3 is
# -9876 and the other three coefficients are odd, so one coefficient in four
# cost 35 adder_carry and 37 sdffre.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_add_evencoef.v
hierarchy -top dspv4_mult_add_evencoef
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_add_evencoef -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_add_evencoef
check -assert
# All three products reached a DSP and both adds were absorbed.
select -assert-count 3 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
select -assert-count 0 t:adder_carry
# The output register went into P rather than staying in fabric. Asserted
# separately from the adder count: absorbing the adder while dropping the
# register would also show zero fabric flops.
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:sdffre
