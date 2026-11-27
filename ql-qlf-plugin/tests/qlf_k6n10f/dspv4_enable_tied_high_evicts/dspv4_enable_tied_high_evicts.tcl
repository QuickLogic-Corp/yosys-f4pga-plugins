# dspv4_enable_tied_high_evicts -- a tied-high enable counts against the
# crossbar's three inputs. Both blocks are in the .v. The Makefile reads the log:
# exactly one port is given up (the evict block's B), and the check pass has
# nothing to warn about, because the cell that was built fits.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_enable_tied_high_evicts.v
hierarchy -top dspv4_enable_tied_high_evicts
$PASS_NAME -family qlf_k6n10f -top dspv4_enable_tied_high_evicts -dspv4 -no_abc9 -lib_path $LIB/
