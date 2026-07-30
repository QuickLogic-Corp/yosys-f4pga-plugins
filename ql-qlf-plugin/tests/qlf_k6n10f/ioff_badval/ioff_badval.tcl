# Negative test -- test-plan 5B.3d.
#
# A negative (or non-numeric) -min_shared_reset value must be a clean log_error.
# Clamping silently to 0 would be the worst available failure mode for a knob
# whose entire purpose is being swept from scripts: the run would look like a
# valid K=-1 data point.
#
# Registered with ioff_badval_negative = 1, so yosys exiting non-zero is a pass.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
hierarchy -top ioff_badval
ql_ioff -min_shared_reset -1
