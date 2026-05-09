# dspv2_macc_inference_smoke
#
# W1.7 smoke: prove ql_dsp_macc -dspv2 infers a plain signed-MAC pattern
# into a single dspv2 wrapper, AND that the post-synth netlist is
# formally equivalent to the original RTL.
#
# Acceptance:
#   - check_equiv_dspv2 passes (equiv_induct -seq 8 + equiv_simple).
#   - Post-opt netlist contains exactly one QL_DSPV2_MULTACC* cell
#     (output FF absorbed: encoding fixed by W1.1, so we expect
#      the _REGOUT typed wrapper).

yosys -import
if { [info procs synth_quicklogic] == {} } { plugin -i ql-qlf }
yosys -import

# Shared formal-equivalence harness (W1.6).
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_macc_inference_smoke.v
design -save read

design -load read
hierarchy -top dspv2_macc_inference_smoke
check_equiv_dspv2 dspv2_macc_inference_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_macc_inference_smoke
select -assert-count 1 t:QL_DSPV2_MULTACC_REGOUT
select -assert-count 1 t:QL_DSPV2_*
