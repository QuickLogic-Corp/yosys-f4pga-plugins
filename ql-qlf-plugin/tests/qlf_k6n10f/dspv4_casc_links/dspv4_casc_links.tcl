# dspv4_casc_links -- chains the pass must link, at -chain_max 12. One block per
# module, each with its own log; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_links.v
design -save read

# The whole flow, with the option going through the wrapper.
proc full_block {name} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    tee -o $name.log $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -chain_max 12 -lib_path $LIB/
    yosys cd $name
    check -assert
}

# Stop the flow before the leaf techmap, so the QL_DSP4 cells can still be
# read, then call the pass the way the flow would. -verbose names each link
# the pass finds. The log is <name>_cells.log.
proc stopped_block {name} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o ${name}_cells.log ql_dspv4 -chain_max 12 -verbose
    tee -a ${name}_cells.log dump t:QL_DSP4
    yosys cd $name
    check -assert
}

# ---- A chain the user instantiated: the pass leaves both cells as they are. --

stopped_block _macro
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i

# ---- Two stages, one link. 000010101 is MULT_ADD, 000000101 is MULT. ---------

full_block _two
stopped_block _two
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i

# ---- Five stages, four links. ------------------------------------------------

full_block _chain
stopped_block _chain
select -assert-count 5 t:QL_DSP4
select -assert-count 4 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i
