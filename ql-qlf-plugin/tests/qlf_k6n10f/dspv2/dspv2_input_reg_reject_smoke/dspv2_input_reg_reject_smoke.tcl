# dspv2_input_reg_reject_smoke
#
# Negative test: a $dff on a_i driven by a different clock (clk2) than
# the DSP wrapper's clock_i (clk).  The absorption pass checks clock-
# domain identity and correctly rejects the mismatched DFF.
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains one QL_DSPV2_MULTACC (not _REGIN).
#   - At least one sdffre survives (the un-absorbed DFF, tech-mapped).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_input_reg_reject_smoke.v
design -save read

design -load read
hierarchy -top dspv2_input_reg_reject_smoke
run_synth_dspv2 dspv2_input_reg_reject_smoke

# Post-opt structural assertions.
# The clock-domain check in run_dspv2() rejects the clk2 DFF.
# It survives as sdffre cells in the final netlist.
design -load postopt
yosys cd dspv2_input_reg_reject_smoke
select -assert-count 1 t:QL_DSPV2_MULTACC
select -assert-count 0 t:QL_DSPV2_MULTACC_REGIN
select -assert-min 1 t:sdffre
