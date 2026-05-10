# dspv2_input_reg_sdff_smoke
#
# Prove ql_dsp -dspv2 absorbs a sync-reset FF feeding a
# wrapper's a_i input into the wrapper's A_REG, AND that the post-synth
# netlist is formally equivalent to the pre-synth RTL.
#
# This exercises the $sdff path in to the FF matcher's
# accept list with SRST_POLARITY / SRST_VALUE / SRST-signal filters.
# Depending on opt-pass ordering, the FF may arrive as $sdff (directly
# absorbed) or as $dff (absorbed by the existing path after
# opt folds the sync reset into mux logic). Both paths are correct.
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains zero $sdff/$dff cells (opt normalises
#     $sdff to $dff; the $dff is then absorbed into the wrapper).
#   - Post-opt netlist contains one QL_DSPV2_MULTACC cell and 16
#     dffre cells (ql_dspv2_types externalizes A_REG as dffre).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

# Shared formal-equivalence harness.
source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_input_reg_sdff_smoke.v
design -save read

design -load read
hierarchy -top dspv2_input_reg_sdff_smoke
run_synth_dspv2 dspv2_input_reg_sdff_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_input_reg_sdff_smoke
select -assert-count 0 t:\$sdff
select -assert-count 0 t:\$dff
select -assert-count 1 t:QL_DSPV2_MULTACC
select -assert-count 16 t:dffre
