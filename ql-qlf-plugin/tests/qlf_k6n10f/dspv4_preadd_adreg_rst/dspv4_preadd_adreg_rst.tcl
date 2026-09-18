# dspv4_preadd_adreg_rst -- a RESETTABLE AD register must stay in fabric.
#
# This is a guard test: it fails if someone widens the AD match back to $sdff.
# The DSP's AD bank resets from the cell-wide RSTN, which this path never
# wires, so absorbing a resettable flop loses the reset and computes wrong
# values after it -- while synthesising, packing and routing perfectly. The
# only visible symptom is the value, which is why the count is pinned here.
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
# The multiply still reaches a DSP -- the refusal degrades to the next smaller
# shape, it does not push the whole thing to soft logic.
select -assert-count 1 t:QL_DSP4_MULT
# The AD bank is NOT used: that is the refusal this test exists to pin.
select -assert-count 0 t:QL_DSP4_AD_DFFR_32
# With the pre-adder refused the addition stays in fabric...
select -assert-min 1 t:adder_carry
# ...and the flop is then just an operand register, which the A bank CAN hold
# because it has a reset. So it is absorbed there rather than left in fabric --
# the refusal costs the pre-adder, not the register.
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
