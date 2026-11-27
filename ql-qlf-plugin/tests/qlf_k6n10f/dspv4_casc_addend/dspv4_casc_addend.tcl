# dspv4_casc_addend -- stages that add the link and one more value, k, at
# -chain_max 12, whose link is made. One block per module, each with its own
# logs; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_addend.v
design -save read

# Stop the flow before the leaf techmap, so the QL_DSP4 cells and the $add
# cells can still be read, then call the pass the way the flow would.
# -verbose names each link and each grouping decision. The log is <log>.log.
proc stopped_block {top log} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $top
    $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o $log.log ql_dspv4 -chain_max 12 -verbose
    tee -a $log.log dump t:QL_DSP4
    yosys cd $top
    check -assert
}

# The whole flow, with the option going through the wrapper. The BLIF of this
# flow has no names that depend on the run.
proc full_block {top log} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $top
    tee -o $log.log $PASS_NAME -family qlf_k6n10f -top $top -dspv4 -no_abc9 -chain_max 12 -lib_path $LIB/
    yosys cd $top
    check -assert
    write_blif $log.blif
}

# Control words: 000000101 MULT, 000010101 MULT_ADD, 000110101 MULT_ADD_C,
# 110010101 MULT_ADD_C_CASC.

# ---- Grouping 2: every $add goes, k on each consumer's C. -------------------

stopped_block _addend _addend
select -assert-count 3 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 %ci1:+\[C\] i:k1 %i
select -assert-count 1 t:QL_DSP4 %ci1:+\[C\] i:k2 %i

stopped_block _addend_g2_swapped _addend_g2_swapped
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i %ci1:+\[C\] i:k %i

# ---- Grouping 1, left to right: each $add but the tail's is grouping 2's. ---

stopped_block _addend_grouped _addend_grouped
select -assert-count 4 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add
select -assert-count 1 t:\$add %ci1:+\[B\] i:k3 %i

# ---- A registered k: its flop stays in fabric and drives C. ------------------

stopped_block _addend_creg _addend_creg
select -assert-count 2 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 1 t:\$dff t:\$sdff t:\$dffe t:\$sdffe %u
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i %ci1:+\[C\] w:k_r %i

# ---- One $add in both groupings: handled once, as grouping 2. ---------------

stopped_block _addend_both _addend_both
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i %ci1:+\[C\] i:k1 %i

# ---- a*b + prev + prev: prev on PCIN and on C. ------------------------------

stopped_block _double_prev _double_prev
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i %ci1:+\[C\] w:prev %i

# ---- The $add reads the result shifted, or under a zero pad: no fold. -------

stopped_block _addend_g1_shifted _addend_g1_shifted
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add

stopped_block _addend_g1_in_zero_pad _addend_g1_in_zero_pad
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:\$add

# ---- A signed link and an unsigned k, padded to a signed value: both fold. --

stopped_block _addend_g2_k_padded _addend_g2_k_padded
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 %ci1:+\[C\] i:k %i

stopped_block _addend_g1_k_padded _addend_g1_k_padded
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 %ci1:+\[C\] i:k %i

# ---- A 50-bit s of two 32 x 18 products: the 50-bit cap lets it fold. -------

stopped_block _addend_g1_cap _addend_g1_cap
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 0 t:\$add

# ---- Two cells' results on one $add: the cell first in name order takes it. -
# Runs 1 and 2 are the same RTL; run 3 has the lines swapped. The same RTL
# through the whole flow twice gives one BLIF.

stopped_block _addend_g1_tie _addend_g1_tie_run1
select -assert-count 4 t:QL_DSP4
select -assert-count 0 t:\$add
stopped_block _addend_g1_tie _addend_g1_tie_run2
select -assert-count 0 t:\$add
stopped_block _addend_g1_tie_swapped _addend_g1_tie_run3
select -assert-count 0 t:\$add
full_block _addend_g1_tie _addend_g1_tie_flow1
full_block _addend_g1_tie _addend_g1_tie_flow2

# ---- The same, but the s1 cell's result also leaves on a port. Both line
# orders: the declined cell sorts first in the first.

stopped_block _addend_g1_tie_partial _addend_g1_tie_partial_run1
select -assert-count 4 t:QL_DSP4
select -assert-count 0 t:\$add
stopped_block _addend_g1_tie_partial_swapped _addend_g1_tie_partial_run2
select -assert-count 4 t:QL_DSP4
select -assert-count 0 t:\$add

# ---- Grouping 2 with the consumer's P register: the $add goes. --------------

stopped_block _addend_g2_preg _addend_g2_preg
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 r:PREG=1'b1 %i %i
select -assert-count 0 t:\$add
