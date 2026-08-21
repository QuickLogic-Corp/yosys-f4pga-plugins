# Negative test -- test-plan 5B.3f.
#
# An unrecognised option must be an error rather than silently ignored, so that
# a stale flag in a device .ys template or a settings JSON fails loudly instead
# of being dropped. This is what extra_args() buys.
#
# Registered with ioff_badopt_negative = 1, so yosys exiting non-zero is a pass.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
hierarchy -top ioff_badopt
ql_ioff -no_such_option
