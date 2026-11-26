# dspv4_casc_addend_refused -- stages with a per-stage addend k whose link,
# or whose fold of the $add, is refused, at -chain_max 12. One block per
# module, each with its own logs; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_addend_refused.v
design -save read

# Stop the flow before the leaf techmap, so the QL_DSP4 cells and the $add
# cells can still be read, then call the pass the way the flow would.
# -verbose names each link, each refusal and each declined grouping.
proc stop_and_link {name} {
    global PASS_NAME LIB
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o $name.log ql_dspv4 -chain_max 12 -verbose
    tee -a $name.log dump t:QL_DSP4
    yosys cd $name
    check -assert
}

proc stopped_block {name} {
    design -load read
    stop_and_link $name
}

# A block whose module is the one module of its own file.
proc own_file_block {name file} {
    design -reset
    read_verilog $file
    stop_and_link $name
}

# The whole flow, with the option going through the wrapper, which calls the
# pass twice. The log is <name>_flow.log.
proc full_block {name} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    tee -o ${name}_flow.log $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -chain_max 12 -lib_path $LIB/
    yosys cd $name
    check -assert
}

# Control words: 000000101 MULT, 000010101 MULT_ADD, 000110101 MULT_ADD_C,
# 110010101 MULT_ADD_C_CASC, 000100101 MULT_ACC.

# The blocks run in the order of test-plan-blocks.md §5's table.

stopped_block _addend_reglink
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 1 t:\$add

stopped_block _reglink_grp2_creg
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 2 t:QL_DSP4 r:PREG=1'b0 %i
select -assert-count 1 t:\$add

full_block _addend_shared
stopped_block _addend_shared
select -assert-count 2 t:QL_DSP4

full_block _addend_g2_narrow
stopped_block _addend_g2_narrow
select -assert-count 2 t:QL_DSP4

stopped_block _addend_g1_narrow
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add

stopped_block _addend_g1_shared
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add

full_block _addend_g2_link_narrow
stopped_block _addend_g2_link_narrow
select -assert-count 2 t:QL_DSP4

full_block _addend_g2_unsigned
stopped_block _addend_g2_unsigned
select -assert-count 2 t:QL_DSP4

stopped_block _addend_g1_unsigned
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add

full_block _addend_g2_pad
stopped_block _addend_g2_pad
select -assert-count 2 t:QL_DSP4

stopped_block _addend_g2_slice
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:\$add

stopped_block _addend_g2_in_slice
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:\$add

stopped_block _addend_g2_in_multicell
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:\$add

stopped_block _addend_g2_multicell
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:\$add

full_block _addend_g2_unsigned_in_pad
stopped_block _addend_g2_unsigned_in_pad
select -assert-count 2 t:QL_DSP4

stopped_block _addend_g1_wide_y
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add

stopped_block _addend_g1_preg
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 r:PREG=1'b1 %i %i
select -assert-count 1 t:\$add

# Grouping 1 below an accumulator, from a file of its own, last.
own_file_block _addend_g1_full_port dspv4_casc_addend_g1_full_port.v
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000100101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add
