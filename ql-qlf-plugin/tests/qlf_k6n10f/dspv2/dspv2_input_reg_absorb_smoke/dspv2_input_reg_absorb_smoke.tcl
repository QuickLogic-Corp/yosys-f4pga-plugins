# dspv2_input_reg_absorb_smoke
#
# Prove ql_dsp -dspv2 absorbs a $dff feeding a wrapper's
# a_i input into the wrapper's A_REG, AND that the post-synth netlist
# is formally equivalent to the pre-synth RTL.
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains zero $dff cells (absorbed into the
#     wrapper, not retained alongside it).
#   - Post-opt netlist contains exactly one QL_DSPV2_*_REGIN* cell
#     (the typed wrapper carries a REGIN suffix because A_REG=1).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

# Shared formal-equivalence harness.
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_input_reg_absorb_smoke.v
design -save read

design -load read
hierarchy -top dspv2_input_reg_absorb_smoke
run_synth_dspv2 dspv2_input_reg_absorb_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_input_reg_absorb_smoke
select -assert-count 0 t:\$dff
select -assert-count 1 t:QL_DSPV2_*REGIN*
