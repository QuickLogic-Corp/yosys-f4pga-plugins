# dspv4_macc_areset -- an async-reset accumulator stays in fabric.
#
# This is the shape dspv4_macc used to have. It passed while absorbing nothing,
# because its only fabric check was `$add == 0` and a fabric accumulator is
# adder_carry plus LUTs by then, not $add. Pinned here as its own case so the
# limitation is documented rather than hidden inside a test that claims the
# opposite.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_areset.v
hierarchy -top dspv4_macc_areset
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_areset -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_areset
# The multiply is still worth a DSP.
select -assert-count 1 t:QL_DSP4_MULT
# The accumulator is not in the DSP -- no bank can hold an async reset.
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
