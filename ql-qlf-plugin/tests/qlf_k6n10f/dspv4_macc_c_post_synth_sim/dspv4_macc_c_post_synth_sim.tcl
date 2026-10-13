# dspv4_macc_c_post_synth_sim -- synthesise each module on its own and write
# the netlist under a _syn name, so the testbench can run it beside the RTL.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_ql
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_c_post_synth_sim.v
design -save rtl

foreach top {dspv4_macc_c dspv4_macc_c_reader dspv4_macc_c_self dspv4_mult_regin_port} {
    design -load rtl
    hierarchy -top $top
    $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -lib_path $LIB/
    yosys rename $top ${top}_syn
    write_verilog -noattr sim/${top}_post_synth.v
}
