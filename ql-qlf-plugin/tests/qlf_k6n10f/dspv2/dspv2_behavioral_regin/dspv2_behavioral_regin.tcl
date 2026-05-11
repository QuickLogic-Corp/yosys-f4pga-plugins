# dspv2_behavioral_regin
#
# Behavioral RTL test: a registered multiply written in pure RTL
# (no wrapper instantiation). The design goes through the full
# mul2dsp → techmap → ql_dsp -dspv2 absorption → ql_dspv2_types flow.
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains zero $dff cells (absorbed into DSP).
#   - Post-opt netlist contains exactly one QL_DSPV2_*_REGIN* cell
#     (clock adopted from FF, A_REG=1, _REGIN suffix applied).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_behavioral_regin.v
design -save read

design -load read
hierarchy -top dspv2_behavioral_regin
run_synth_dspv2 dspv2_behavioral_regin

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_behavioral_regin
select -assert-count 0 t:\$dff
select -assert-count 1 t:QL_DSPV2_*REGIN*
