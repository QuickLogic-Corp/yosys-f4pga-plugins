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

# A small positive N still runs the cascade step: the chain of four is cut
# after every third cell.
block _n3      chain4 {-chain_max 3}

# _fanout_det: the same design twice at -chain_max 12. Rule 3 picks one of two
# consumers, the same one each run, so the two netlists are one.
block _fanout_det_run1 fanout_det {-chain_max 12}
block _fanout_det_run2 fanout_det {-chain_max 12}

# _too_long, _too_long_2: chains longer than N = 4. The pass is called by hand
# after the flow stops before the leaf techmap, so -verbose names each refusal.
proc limited_block {name top} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $top
    $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o $name.log ql_dspv4 -chain_max 4 -verbose
    tee -a $name.log dump t:QL_DSP4
    yosys cd $top
    check -assert
}
limited_block _too_long chain5
select -assert-count 5 t:QL_DSP4
limited_block _too_long_2 chain9
select -assert-count 9 t:QL_DSP4

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

# -chain_max reaches ql_dspv4 only with -dspv4, without -synplify and with DSPs
# mapped. Anywhere else synth_ql warns that the option is ignored; the control
# run with -dspv4 prints no such warning.
proc warning_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top chain4
    tee -o $name.log $PASS_NAME -family qlf_k6n10f -top chain4 -no_abc9 {*}$flags -chain_max 8 -lib_path $LIB/
}
warning_block _ignored_no_dspv4 {}
warning_block _ignored_synplify {-dspv4 -synplify}
warning_block _ignored_no_dsp {-dspv4 -no_dsp}
warning_block _applied {-dspv4}
