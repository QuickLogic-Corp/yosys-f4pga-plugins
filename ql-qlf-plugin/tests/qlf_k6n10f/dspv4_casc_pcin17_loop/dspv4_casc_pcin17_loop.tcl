# dspv4_casc_pcin17_loop -- loops of PCIN >> 17 reads: each loop loses one
# link and keeps the rest. One block per module, each module in a file of its
# own; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

# The whole flow, with the options going through the wrapper. The log is
# <name>.log.
proc full_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    tee -o $name.log $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 {*}$flags -lib_path $LIB/
    yosys cd $name
    check -assert
}

# The flow stopped before the leaf techmap, so the QL_DSP4 cells can still be
# read. It runs the map_dsp steps up to the second pass call, with `flags`
# forwarded to both ql_dspv4 calls. The log is <name>_cells.log.
proc stopped_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o ${name}_cells.log ql_dspv4 {*}$flags -verbose
    techmap -map +/mul2dsp.v -D DSP_A_MAXWIDTH=32 -D DSP_B_MAXWIDTH=18 -D DSP_A_MINWIDTH=2 -D DSP_B_MINWIDTH=2 -D DSP_SIGNEDONLY -D DSP_NAME=\$__QL_DSP4_MUL
    chtype -set \$mul t:\$__QL_DSP4_MUL
    select a:mul2dsp
    setattr -unset mul2dsp
    opt_expr -fine
    wreduce
    select -clear
    tee -a ${name}_cells.log ql_dspv4 {*}$flags -verbose
    tee -a ${name}_cells.log dump t:QL_DSP4
    yosys cd $name
    check -assert
}

# Both runs of a block. Its module is the one module of its own file, read
# after design -reset: which cell keeps a register, or gets the first name,
# follows the order of the lines, so each file pins it.
proc own_file_block {name file flags} {
    design -reset
    read_verilog $file
    design -save read
    full_block $name $flags
    stopped_block $name $flags
}

# Control words: 001010101 MULT_ADD_PCIN17, 000110101 MULT_ADD_C.

# ---- Loops with one register. Each block asserts its fold first: only s1 has
# a P register and no cell registers C. ----------------------------------------

# s1 and s2 read each other >>> 17. The loop loses the link out of s1, so s2
# reads s1 on C, and s1 reads s2 on PCIN.

own_file_block _loop dspv4_casc_pcin17_loop.v {}
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i %co1:+\[P\] w:s1 %i
select -assert-count 2 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[PCIN\] w:* %i

# s1 -> s2 -> s3 -> s1. Without the link out of s1, s2 -> s3 -> s1 is a chain
# of three cells. With no -chain_max the cap is 2, so s1 reads s3 on C.

own_file_block _loop3 dspv4_casc_pcin17_loop3.v {}
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i %co1:+\[P\] w:s1 %i
select -assert-count 3 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:s3 %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s3 %i

# The same RTL at -chain_max 3: the chain of three fits.

own_file_block _loop3_at_cap dspv4_casc_pcin17_loop3_at_cap.v {-chain_max 3}
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i %co1:+\[P\] w:s1 %i
select -assert-count 3 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:s3 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s1 %i

# ---- No register on the loop (a combinational loop in the RTL). The link into
# the cell first in name order, s1, is dropped, and Yosys finishes: s1 reads s2
# on C, and s2 reads s1 on PCIN. ------------------------------------------------

own_file_block _loop_no_register dspv4_casc_pcin17_loop_no_register.v {}
select -assert-count 2 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:PREG=1'b0 %i
select -assert-count 2 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:s1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:s2 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[PCIN\] w:* %i
