# dspv4_mult_shared_chain -- multiple DSPs competing for the same register.
#
# Primarily a crash regression. With MREG inference but without the
# already-absorbed guard in ql-dspv4.cc, this design segfaults the pass: a
# product register is claimed by two DSPs and removed twice (pmgen's deferred
# autoremove plus the pending_removal drain). Reaching `check -assert` at all is
# most of the value here.
#
# The assertions are deliberately loose about WHICH shapes win. Three multiplies
# share two adders, so the matcher legitimately has several valid coverings and
# the split between M stages and P registers depends on match order. Pinning
# exact bank counts would make this a change-detector rather than a bug-detector.
# What must hold: all three multiplies reach a DSP, none is left soft, and no
# flop is stranded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_shared_chain.v
hierarchy -top dspv4_mult_shared_chain
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_shared_chain -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_shared_chain
check -assert
# Every multiply landed in a DSP.
select -assert-count 3 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# At least one product register was absorbed rather than all of them staying in
# fabric -- the feature is doing something on this shape.
select -assert-min 1 t:QL_DSP4_M_DFFR_50
