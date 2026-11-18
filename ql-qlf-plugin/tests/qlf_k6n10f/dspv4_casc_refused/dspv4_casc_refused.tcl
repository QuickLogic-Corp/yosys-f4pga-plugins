# dspv4_casc_refused -- reads of another DSP's result that must stay on C, at
# -chain_max 12. One block per module, each with its own log; the Makefile's
# verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_refused.v
design -save read

# Stop the flow before the leaf techmap, so the QL_DSP4 cells can still be
# read, then call the pass the way the flow would. -verbose names each link
# the pass finds or refuses.
proc stopped_block {name} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o $name.log ql_dspv4 -chain_max 12 -verbose
    tee -a $name.log dump t:QL_DSP4
    yosys cd $name
}

# ---- Read unsigned: found, and refused with a reason. ------------------------

stopped_block _unsigned
select -assert-count 2 t:QL_DSP4

stopped_block _pad
select -assert-count 2 t:QL_DSP4

# ---- Not a whole result read from bit 0: not a link, and no reason. ----------

stopped_block _slice
select -assert-count 2 t:QL_DSP4

stopped_block _multicell
select -assert-count 3 t:QL_DSP4

# ---- A stage in a mode that has no PCIN form: the finder does not look. ------

stopped_block _sub
select -assert-count 2 t:QL_DSP4

stopped_block _acc_tail
select -assert-count 2 t:QL_DSP4

stopped_block _preadd_b
select -assert-count 2 t:QL_DSP4
