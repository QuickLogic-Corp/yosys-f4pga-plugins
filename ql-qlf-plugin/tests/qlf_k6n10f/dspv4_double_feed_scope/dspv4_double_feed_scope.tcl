# dspv4_double_feed_scope -- the double-feed check leaves these alone.
#
# Each block shares an operand between two ports. The first three never use
# the pre-adder, so the bus mux the check protects is never in play. Of the
# other seven, pipe is the one block a check run again after register
# absorption would wrongly refuse, aa is the one a check that compared all
# four ports would wrongly refuse, pipe2/two_en/mulr/addr each absorb a
# register on one side only (or a two-deep chain, pipe2), so the check must
# still pass them one at a time, not only pipe's own shape, and cst shares a
# constant, not a signal, between the two ports: a constant has no wire, so
# it is not a shared operand (OQ-X3), and the check never sees it. The modes
# line in the Makefile is the main assertion: it must match P4 exactly.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import
set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]
# A stale netlist from an earlier run must not let the x-grep rule pass on
# nothing: delete it first, so a run that crashes before write_verilog
# leaves no file for `test -s` to find.
file delete -force netlist.v
read_verilog dspv4_double_feed_scope.v
hierarchy -top dspv4_double_feed_scope
$PASS_NAME -family qlf_k6n10f -top dspv4_double_feed_scope -dspv4 -no_abc9 -lib_path $LIB/
yosys cd dspv4_double_feed_scope
check -assert
select -assert-count 10 t:QL_DSP4_MULT
select -assert-count 7 t:QL_DSP4_PREADD
# pipe is the only block that registers the pre-adder's own sum: AD holds
# s_r. pipe2 is the only one that registers D, and the only one whose B-side
# chain is two deep (B1 and B2 both used). The other single-stage B
# registers (pipe, two_en, mulr) each land in B2, not B1. The single-stage A
# registers (pipe2, two_en, addr) each land in A2, not A1.
select -assert-count 1 t:QL_DSP4_AD_DFFR_32
select -assert-count 1 t:QL_DSP4_D_DFFRE_27
select -assert-count 1 t:QL_DSP4_B1_DFFRE_18
select -assert-count 4 t:QL_DSP4_B2_DFFRE_18
select -assert-count 3 t:QL_DSP4_A2_DFFRE_32
select -assert-count 0 t:QL_DSP4_A1_DFFRE_32
select -assert-count 0 t:QL_DSP4_PRESUB
select -assert-count 0 t:adder_carry
write_verilog -noattr netlist.v
