# dspv2_mult_lowering_smoke
#
# W1.x companion to W1.7-W1.9: prove the pure-comb $mul lowering chain
# in synth_quicklogic -dspv2 produces a single QL_DSPV2 typed wrapper
# AND that the post-synth netlist is formally equivalent to the
# original RTL.
#
# Lowering chain exercised:
#   $mul -> mul2dsp + dspv2_map.v -> dspv2_32x18x64_cfg_ports
#                                 -> dspv2_final_map -> QL_DSPV2
#                                 -> ql_dspv2_types  -> QL_DSPV2_MULT
#
# Acceptance:
#   - check_equiv_dspv2 passes (equiv_induct -seq 8 + equiv_simple).
#   - Post-opt netlist contains exactly one QL_DSPV2_MULT cell (no
#     REG suffixes -- pure combinational mult).

yosys -import
if { [info procs synth_quicklogic] == {} } { plugin -i ql-qlf }
yosys -import

# Shared formal-equivalence harness (W1.6).
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_mult_lowering_smoke.v
design -save read

design -load read
hierarchy -top dspv2_mult_lowering_smoke
check_equiv_dspv2 dspv2_mult_lowering_smoke

# Post-opt structural assertion on the gate netlist.
design -load postopt
yosys cd dspv2_mult_lowering_smoke
select -assert-count 1 t:QL_DSPV2_MULT
select -assert-count 1 t:QL_DSPV2_*
