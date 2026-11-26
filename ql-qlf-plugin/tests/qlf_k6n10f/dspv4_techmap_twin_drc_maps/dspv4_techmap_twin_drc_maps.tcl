# dspv4_techmap_twin_drc_maps -- the cells of dspv4_techmap_refused_drc with the
# rule satisfied. All five must map: no QL_DSP4 is left, and there is a
# leaf cell for each. A cell that stopped mapping would stay a QL_DSP4 and the
# run would stop.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_techmap_twin_drc_maps.v
hierarchy -top dspv4_techmap_twin_drc_maps
$PASS_NAME -family qlf_k6n10f -top dspv4_techmap_twin_drc_maps -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_techmap_twin_drc_maps
select -assert-none t:QL_DSP4
