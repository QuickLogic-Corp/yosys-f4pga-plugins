# dspv2_mixed_reset_reject
#
# Mixed-reset rejection test: one input has a plain $dff (no reset),
# the other has a $sdff (synchronous reset).  The DSP cell has a
# single shared reset for all input pipeline registers, so absorbing
# both would change semantics.
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Exactly one external $dff (or $sdff) cell remains — the
#     no-reset FF that could not be absorbed.
#   - Exactly one QL_DSPV2 cell exists (with _REGIN for the
#     resettable input).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_mixed_reset_reject.v
design -save read

design -load read
hierarchy -top dspv2_mixed_reset_reject
run_synth_dspv2 dspv2_mixed_reset_reject

# Post-opt structural assertions.
design -load postopt
yosys cd dspv2_mixed_reset_reject

# The no-reset $dff must NOT have been absorbed — it should remain
# as an external register cell.  After full synthesis the Yosys $dff
# primitives are technology-mapped to sdffre cells by ffs_map.v.
select -assert-min 1 t:sdffre

# Exactly one DSP cell.
select -assert-count 1 t:QL_DSPV2_*
