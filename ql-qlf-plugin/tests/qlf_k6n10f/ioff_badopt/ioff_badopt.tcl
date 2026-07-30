# Negative test -- test-plan 5B.3f.
#
# `-min_shared_rest` (one missing `e`) must be an error rather than silently
# ignored. This is what extra_args() buys: without it the pass would run at K=0
# and produce a sweep row that looks like data but is not.
#
# Registered with ioff_badopt_negative = 1, so yosys exiting non-zero is a pass.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
hierarchy -top ioff_badopt
ql_ioff -min_shared_rest 2
