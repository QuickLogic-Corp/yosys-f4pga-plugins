# dspv4_mult_regin -- operand register absorption with latency balancing.
#
# Phase 3 T3.1/T3.2. The assertion that matters is the flop count: exactly one
# stage per operand is absorbed, so of the three design flops two move into the
# DSP's AREG1/BREG1 and one -- B's surplus -- stays outside. Absorbing all three
# would be the latency bug: A would reach the multiplier a cycle later than the
# RTL says. Absorbing none would be the QoR cliff.
#
# Values are covered by scripts/dspv4/verify_inference.py, shape
# mult_regin_asym; this pins the structure.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_regin.v
hierarchy -top dspv4_mult_regin
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_regin -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_regin
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# One stage per operand moved inside, and B's surplus stage stayed out.
#
# A2/B2 are the single-stage slots (AREG1/BREG1); A2 is 32 wide because the A
# port is, so the operand's sign extension is registered with it. The 18 fabric
# dffre are B's second stage -- the one latency balancing refused to absorb.
select -assert-count 32 t:QL_DSP4_A2_DFFRE
select -assert-count 18 t:QL_DSP4_B2_DFFRE
select -assert-count 18 t:dffre
# The two-stage slots must stay empty: using them would be the latency bug.
select -assert-count 0 t:QL_DSP4_A1_DFFRE
select -assert-count 0 t:QL_DSP4_B1_DFFRE

