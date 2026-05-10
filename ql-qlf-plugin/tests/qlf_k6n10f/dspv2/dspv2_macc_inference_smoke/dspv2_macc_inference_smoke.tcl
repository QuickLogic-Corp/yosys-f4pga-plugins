# dspv2_macc_inference_smoke
#
# Smoke test: verify ql_dsp_macc -dspv2 infers a plain signed-MAC pattern
# into a single QL_DSPV2_MULTACC cell with correct port connections.
#
# For some tests the equiv_induct pass seems to hang if opt_expr + opt_clean
# are not invoked after techmapping. Therefore run_synth_dspv2 is used
# instead of the equiv_opt pass.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

# Shared equivalence-check harness.
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_macc_inference_smoke.v
design -save read

design -load read
hierarchy -top dspv2_macc_inference_smoke
run_synth_dspv2 dspv2_macc_inference_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_macc_inference_smoke
select -assert-count 1 t:QL_DSPV2_MULTACC
select -assert-count 1 t:QL_DSPV2_*
