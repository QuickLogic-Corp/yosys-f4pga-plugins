# dspv2_unsigned_reject
#
# Negative test: unsigned 16x9 MAC must NOT be inferred as QL_DSPV2_MULTACC.
#
# The ql_dsp_macc -dspv2 pass explicitly rejects unsigned operands.
# The multiply still lands in a DSPv2 MULT cell via mul2dsp fallback,
# but the accumulate loop remains in generic cells ($add / $dff).
#
# Acceptance:
#   - run_synth_dspv2 completes without error.
#   - Post-opt netlist contains zero QL_DSPV2_MULTACC cells.
#   - Post-opt netlist still contains at least one QL_DSPV2_* cell
#     (the multiply itself is lowered to DSP).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

source [file join [file dirname [info script]] .. dspv2_equiv.tcl]

read_verilog dspv2_unsigned_reject.v
design -save read

design -load read
hierarchy -top dspv2_unsigned_reject
run_synth_dspv2 dspv2_unsigned_reject

# Post-opt structural assertions on the gate netlist.
design -load postopt
yosys cd dspv2_unsigned_reject
select -assert-count 0 t:QL_DSPV2_MULTACC
select -assert-min  1 t:QL_DSPV2_*
