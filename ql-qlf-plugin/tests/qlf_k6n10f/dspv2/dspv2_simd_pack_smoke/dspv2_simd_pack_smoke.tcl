# dspv2_simd_pack_smoke
#
# W1.8 smoke: prove two independent signed-MAC patterns sharing
# clk/rst/en are SIMD-packed into a single QL_DSPV2 wrapper by
# synth_quicklogic -dspv2, AND that the post-synth netlist is
# formally equivalent to the original RTL.
#
# Acceptance:
#   - check_equiv_dspv2 passes (equiv_induct -seq 8 + equiv_simple).
#   - Post-opt netlist contains exactly one QL_DSPV2_* cell -- both
#     halves must end up in the same wrapper. Two cells means
#     ql_dsp_simd -dspv2 failed to pack.

yosys -import
if { [info procs synth_quicklogic] == {} } { plugin -i ql-qlf }
yosys -import

# Shared formal-equivalence harness (W1.6).
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_simd_pack_smoke.v
design -save read

design -load read
hierarchy -top dspv2_simd_pack_smoke
check_equiv_dspv2 dspv2_simd_pack_smoke

# Post-opt structural assertion on the gate netlist.
design -load postopt
yosys cd dspv2_simd_pack_smoke
select -assert-count 1 t:QL_DSPV2_*
