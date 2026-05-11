# dspv2_mult16x9_smoke
#
# Prove the pure-combinational $mul lowering chain for 16×9 operands
# produces a single QL_DSPV2_MULT cell via the fractured-half path.
#
# Lowering chain exercised:
#   $mul → mul2dsp + dspv2_map.v → dspv2_16x9x32_cfg_ports
#                                → dspv2_final_map → QL_DSPV2
#                                → ql_dspv2_types  → QL_DSPV2_MULT
#
# Complements dspv2_mult_lowering_smoke (which tests the 32×18 path).
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains exactly one QL_DSPV2_MULT cell.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_mult16x9_smoke.v
design -save read

design -load read
hierarchy -top dspv2_mult16x9_smoke
run_synth_dspv2 dspv2_mult16x9_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_mult16x9_smoke
select -assert-count 1 t:QL_DSPV2_MULT
select -assert-count 1 t:QL_DSPV2_*
