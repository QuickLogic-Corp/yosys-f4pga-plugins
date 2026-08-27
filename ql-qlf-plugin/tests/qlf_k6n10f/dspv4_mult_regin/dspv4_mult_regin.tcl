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
# Each port absorbs its OWN depth: A is one deep so it takes AREG1 only, B is
# two deep so it takes BREG0 and BREG1. Nothing is left in fabric.
#
# A2 is 32 wide because the A port is -- the operand's sign extension is
# registered with it. B1/B2 are 18, the width of the B port.
select -assert-count 32 t:QL_DSP4_A2_DFFRE
select -assert-count 18 t:QL_DSP4_B2_DFFRE
select -assert-count 18 t:QL_DSP4_B1_DFFRE
# A's stage-0 slot stays empty. Filling it for a one-deep chain would be the
# (1,0) encoding, which reads as delay 0 rather than delay 1.
select -assert-count 0 t:QL_DSP4_A1_DFFRE
# Nothing may remain outside -- absorbing is the whole point of the test.
select -assert-count 0 t:dffre
select -assert-count 0 t:sdffre
