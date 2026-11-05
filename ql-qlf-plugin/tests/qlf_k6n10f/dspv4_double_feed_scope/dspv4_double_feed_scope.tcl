# dspv4_double_feed_scope -- the double-feed check leaves these alone.
#
# Each block shares an operand between two ports. The first three never use
# the pre-adder, so the bus mux the check protects is never in play. The last
# two, pipe and aa, do use the pre-adder, and are the check's real coverage:
# pipe is the one block a check run again after register absorption would
# wrongly refuse, and aa is the one a check that compared all four ports
# would wrongly refuse. The modes line in the Makefile is the main
# assertion: it must match P4 exactly.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import
set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]
read_verilog dspv4_double_feed_scope.v
hierarchy -top dspv4_double_feed_scope
$PASS_NAME -family qlf_k6n10f -top dspv4_double_feed_scope -dspv4 -no_abc9 -lib_path $LIB/
yosys cd dspv4_double_feed_scope
check -assert
select -assert-count 5 t:QL_DSP4_MULT
select -assert-count 2 t:QL_DSP4_PREADD
# pipe: the B bank holds a_r and AD holds s_r. The B register is what
# keeps a and a_r apart at the pre-adder's input mux.
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
select -assert-count 1 t:QL_DSP4_AD_DFFR_32
select -assert-count 0 t:QL_DSP4_PRESUB
select -assert-count 0 t:adder_carry
