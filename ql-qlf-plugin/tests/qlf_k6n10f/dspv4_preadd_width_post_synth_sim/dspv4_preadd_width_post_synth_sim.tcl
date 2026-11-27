# dspv4_preadd_width_post_synth_sim -- each design beside its synthesised
# netlist; the sim compares the products. Modes are checked by the tests the
# .v header names.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import
set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_width_post_synth_sim.v
design -save rtl

foreach shape {ones32 onesa ones28 ones18 ones18b onesb onestrunc copies unsdiff tie diffb diffa} {
    set top dspv4_preadd_width_$shape
    design -load rtl
    hierarchy -top $top
    $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $top
    check -assert
    yosys cd
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}
