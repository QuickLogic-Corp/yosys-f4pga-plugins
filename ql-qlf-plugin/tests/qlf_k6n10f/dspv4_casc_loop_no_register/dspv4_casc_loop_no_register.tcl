# dspv4_casc_loop_no_register -- loops of plain links with no register on them
# (a combinational loop in the RTL). Each loop loses the link into the cell
# first in name order, the rest links, and Yosys finishes. One block per module,
# each module in a file of its own; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

# The whole flow, with the option going through the wrapper. The log is
# <name>_flow.log.
proc full_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    tee -o ${name}_flow.log $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 {*}$flags -lib_path $LIB/
    yosys cd $name
    check -assert
}

# The flow stopped before the leaf techmap, so the QL_DSP4 cells can still be
# read. -verbose names each link the pass finds or refuses. The log is <name>.log.
proc stopped_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o $name.log ql_dspv4 {*}$flags -verbose
    tee -a $name.log dump t:QL_DSP4
    yosys cd $name
    check -assert
}

# Both runs of a block. Its module is the one module of its own file, read
# after design -reset: the order of the lines decides which cell is met first,
# so which cell gets the first name.
proc own_file_block {name file flags} {
    design -reset
    read_verilog $file
    design -save read
    full_block $name $flags
    stopped_block $name $flags
}

# Control words: 000010101 MULT_ADD, 000110101 MULT_ADD_C.

# ---- Two sums that read each other. The link into s1's cell is dropped, so s1
# reads s2 on C, and s2 reads s1 on PCIN. The smallest -chain_max that runs the
# loop rule. ------------------------------------------------------------------

own_file_block _ring2 dspv4_casc_loop_no_register.v {-chain_max 2}
select -assert-count 2 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:PREG=1'b0 %i
select -assert-count 2 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b000010101 %i %co1:+\[PCOUT\] w:* %i

# ---- The same two sums with the lines exchanged: the cell met first is s2's,
# so the link into s2's cell is dropped. -------------------------------------

own_file_block _ring2_swapped dspv4_casc_loop_no_register_swapped.v {-chain_max 12}
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i

# ---- s1 -> s2 -> s3 -> s1. The link into s1's cell is dropped, and the other
# two links make a chain of three. -------------------------------------------

own_file_block _ring3 dspv4_casc_loop_no_register_ring3.v {-chain_max 12}
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s3 %i
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %co1:+\[P\] w:s3 %i

# ---- A ring of two, and a third sum that reads s1. The loop link is dropped,
# then s1's two readers compete: the cell first in name order, s3's, keeps the
# link, and s2 reads s1 on C. ---------------------------------------------------

own_file_block _ring2_tail dspv4_casc_loop_no_register_tail.v {-chain_max 12}
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %co1:+\[P\] w:s3 %i
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b000110101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s1 %i
