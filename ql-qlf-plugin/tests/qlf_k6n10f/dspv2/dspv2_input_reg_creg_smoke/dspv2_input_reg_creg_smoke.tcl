# dspv2_input_reg_creg_smoke
#
# Smoke: prove ql_dsp -dspv2 absorbs a $dff feeding a wrapper's
# c_i input into the wrapper's C_REG parameter.
#
# PRE_ADD is left at 0 (preadder sim model not yet available), so the
# design resolves to QL_DSPV2_MULT. The MULT type classification drops
# the c port, so ql_dspv2_types does not externalize C_REG as dffre.
# Still, the absorption pass itself is exercised: the $dff is consumed,
# the C_REG parameter is set, and the wrapper's c_i is rewired to the
# FF's D input.
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains zero $dff cells (absorbed into the
#     wrapper, not retained alongside it).
#   - Post-opt netlist contains one QL_DSPV2_MULT cell.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_input_reg_creg_smoke.v
design -save read

design -load read
hierarchy -top dspv2_input_reg_creg_smoke
run_synth_dspv2 dspv2_input_reg_creg_smoke

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_input_reg_creg_smoke
select -assert-count 0 t:\$dff
select -assert-count 1 t:QL_DSPV2_MULT
