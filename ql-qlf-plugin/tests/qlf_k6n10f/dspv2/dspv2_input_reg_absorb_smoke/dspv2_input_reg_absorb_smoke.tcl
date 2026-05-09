# dspv2_input_reg_absorb_smoke
#
# W1.9 smoke: prove ql_dsp -dspv2 absorbs a $dff feeding a wrapper's
# a_i input into the wrapper's A_REG, AND that the post-synth netlist
# is formally equivalent to the pre-synth RTL.
#
# Acceptance:
#   - check_equiv_dspv2 passes (equiv_induct -seq 8 + equiv_simple).
#   - Post-opt netlist contains zero $dff cells (the input register
#     was absorbed, not retained alongside the wrapper).
#   - Post-opt netlist contains exactly one QL_DSPV2_*_REGIN* cell
#     (the typed wrapper carries a REGIN suffix because A_REG=1).

yosys -import
if { [info procs synth_quicklogic] == {} } { plugin -i ql-qlf }
yosys -import

# Shared formal-equivalence harness (W1.6).
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_input_reg_absorb_smoke.v
design -save read

design -load read
hierarchy -top dspv2_input_reg_absorb_smoke
check_equiv_dspv2 dspv2_input_reg_absorb_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_input_reg_absorb_smoke
select -assert-count 0 t:$dff
select -assert-count 1 t:QL_DSPV2_*REGIN*
