# dspv4_preadd_adreg_rst -- a RESETTABLE AD register must NOT be absorbed.
#
# This is a guard test. It fails if the AD match is widened back to $sdff, or
# if the RSTN check in emit() is dropped. The AD bank resets from the cell-wide
# RSTN, which this path never wires, so absorbing a resettable flop loses the
# reset and computes wrong values after it -- while synthesising, packing and
# routing perfectly. The only visible symptom is the value, which is why the
# structure is pinned here.
#
# The log assertion in tests/Makefile is the other half: the mode must be plain
# MULT, not any PREADD_* word.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_adreg_rst.v
hierarchy -top dspv4_preadd_adreg_rst
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg_rst -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_adreg_rst
check -assert
# The multiply still reaches a DSP: the refusal degrades to the next smaller
# shape, it does not push the whole thing into soft logic.
select -assert-count 1 t:QL_DSP4_MULT
# The AD bank is NOT used. That is the refusal this test exists to pin.
select -assert-count 0 t:QL_DSP4_AD_DFFR_32
# With the AD register left outside the pre-adder cannot be inferred either,
# so the addition stays in fabric.
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-min 1 t:adder_carry
# The flop is then an ordinary operand register, and the A bank CAN hold it
# because it has a reset. So it still moves inside -- the refusal costs the
# pre-adder, not the register.
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
select -assert-count 0 t:dffre
select -assert-count 0 t:sdffre
