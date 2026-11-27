# dspv4_techmap_twin_maps -- the cells of dspv4_techmap_refused_stops with the
# rule satisfied. All four must map: no QL_DSP4 is left, and each cell leaves
# its own multiplier leaf. The leaf count is the mechanism; a cell that stopped
# mapping would be a QL_DSP4 here, and synthesis would stop.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_techmap_twin_maps.v
hierarchy -top dspv4_techmap_twin_maps
$PASS_NAME -family qlf_k6n10f -top dspv4_techmap_twin_maps -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_techmap_twin_maps
select -assert-none t:QL_DSP4
select -assert-count 4 t:QL_DSP4_MULT
