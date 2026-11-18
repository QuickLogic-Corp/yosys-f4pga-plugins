# dspv4_casc_flags -- the -chain_max option. One synthesis call per block, each
# with its own log and its own BLIF; the Makefile's verify line reads both.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_flags.v
design -save read

# Synthesise one module as one block. `flags` is the block's own option list.
proc block {name top flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $top
    tee -o $name.log $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 {*}$flags -lib_path $LIB/
    write_blif $name.blif
}

# The same chain three times: no option, N = 0 and N = 1. All three must give
# the same netlist and no chain report.
block _off_ref chain4 {}
block _off     chain4 {-chain_max 0}
block _n1      chain4 {-chain_max 1}

# _reset: two pass calls in one run, the first with -chain_max 12 and the second
# with no option. The second must make no link. Each call gets a module of its
# own, prepared up to the pass and saved, so that both have cells to work on.
proc prepare {top saved} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $top
    $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    design -save $saved
}
prepare chain_a prep_a
prepare chain_b prep_b
design -load prep_a
tee -o _reset_call1.log ql_dspv4 -chain_max 12
design -load prep_b
tee -o _reset_call2.log ql_dspv4
