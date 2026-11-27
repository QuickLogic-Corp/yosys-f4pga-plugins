# dspv4_casc_refused -- reads of another DSP's result that must stay on C, at
# -chain_max 12. One block per module, each with its own logs; the Makefile's
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

# A block whose module is the one module of its own file.
proc own_file_block {name file} {
    design -reset
    read_verilog $file
    stop_and_link $name
}

# Control words: 000000101 MULT, 000010101 MULT_ADD, 000110101 MULT_ADD_C,
# 000100101 MULT_ACC, 110100101 MULT_ACC_C.

# ---- A registered link: refused, the head's link made. -----------------------

stopped_block _reglink
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 3 t:QL_DSP4 r:PREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i

# ---- A registered link whose register cannot move: refused, with step 0's
# reason. -----------------------------------------------------------------------

stopped_block _reglink_two_regs
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 0 t:QL_DSP4 r:PREG=1'b1 %i r:CREG=1'b1 %i

stopped_block _reglink_clock
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i

stopped_block _reglink_kept_sum
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 0 t:QL_DSP4 r:PREG=1'b1 %i

stopped_block _reglink_two_consumers_diff
select -assert-count 4 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 4 t:QL_DSP4 r:PREG=1'b0 %i

stopped_block _reglink_two_consumers_neg_diff
select -assert-count 4 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 4 t:QL_DSP4 r:PREG=1'b0 %i

# The register on the port loads on other_en: it stays, and so does CREG.
stopped_block _reglink_copy_diff_en
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i %ci1:+\[CEC\] i:clk_en %i
select -assert-count 0 t:QL_DSP4 r:PREG=1'b1 %i
select -assert-count 1 t:\$dff t:\$sdff t:\$dffe t:\$sdffe %u
select -assert-count 1 t:\$sdffe %ci1:+\[EN\] i:other_en %i

# The move would give the source a fourth distinct clock enable: the register
# stays in the consumer's C bank, and the link is refused for it.
stopped_block _reglink_enables
select -assert-count 2 t:QL_DSP4
select -assert-count 0 t:QL_DSP4 r:PREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:CREG=1'b1 %i %ci1:+\[CEC\] i:en_p %i

# ---- Read unsigned: found, and refused with a reason. ------------------------

full_block _unsigned
stopped_block _unsigned
select -assert-count 2 t:QL_DSP4

full_block _pad
stopped_block _pad
select -assert-count 2 t:QL_DSP4

# ---- Not a whole result read from bit 0: not a link, and no reason. ----------

full_block _slice
stopped_block _slice
select -assert-count 2 t:QL_DSP4

full_block _multicell
stopped_block _multicell
select -assert-count 3 t:QL_DSP4

# ---- A sum too narrow for the source's P range, read into a wider result. ----
# The last three sources are a subtract, a B-path pre-adder and a cross-path cell.

full_block _chain_tight
stopped_block _chain_tight
select -assert-count 4 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i

full_block _head_addend
stopped_block _head_addend
select -assert-count 2 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b000110101 %i

full_block _full_port_chain
stopped_block _full_port_chain
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110100101 %i

full_block _width_reset
stopped_block _width_reset
select -assert-count 4 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i
select -assert-count 3 t:QL_DSP4 r:OPMODE=9'b000110101 %i

full_block _sub_source
stopped_block _sub_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:ALUMODE=2'b11 %i

full_block _preadd_b_source
stopped_block _preadd_b_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREADDINSEL=1'b1 %i

full_block _xpath_source
stopped_block _xpath_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i

# The remaining P range rows, one source each. Each select pins the source's
# control word: ALUMODE 01 is the reverse subtract, INMODE 01100 a subtracting
# pre-adder, 00100 an adding one, and AMULTSEL or BMULTSEL the side the
# pre-adder feeds.

full_block _rsub_source
stopped_block _rsub_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:ALUMODE=2'b01 %i

full_block _preadd_a_sub_source
stopped_block _preadd_a_sub_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:AMULTSEL=1'b1 %i r:INMODE=5'b01100 %i r:OPMODE=9'b000000101 %i

full_block _preadd_a_sub_c_source
stopped_block _preadd_a_sub_c_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:AMULTSEL=1'b1 %i r:INMODE=5'b01100 %i r:OPMODE=9'b000110101 %i

full_block _preadd_b_mult_source
stopped_block _preadd_b_mult_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:BMULTSEL=1'b1 %i r:INMODE=5'b00100 %i r:OPMODE=9'b000000101 %i

full_block _preadd_b_sub_source
stopped_block _preadd_b_sub_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:BMULTSEL=1'b1 %i r:INMODE=5'b01100 %i r:OPMODE=9'b000000101 %i

full_block _preadd_b_sub_c_source
stopped_block _preadd_b_sub_c_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:BMULTSEL=1'b1 %i r:INMODE=5'b01100 %i r:OPMODE=9'b000110101 %i

full_block _xpath_b_source
stopped_block _xpath_b_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:PREADDINSEL=1'b1 %i r:AMULTSEL=1'b1 %i r:BMULTSEL=1'b0 %i

full_block _preadd_a_mult_source
stopped_block _preadd_a_mult_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:AMULTSEL=1'b1 %i r:INMODE=5'b00100 %i r:OPMODE=9'b000000101 %i

full_block _preadd_a_mult_c_source
stopped_block _preadd_a_mult_c_source
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:AMULTSEL=1'b1 %i r:INMODE=5'b00100 %i r:OPMODE=9'b000110101 %i

# One source, two consumers: the width rule refuses one link, so rule 3 has
# one left and refuses nothing.

full_block _fanout_narrow
stopped_block _fanout_narrow
select -assert-count 3 t:QL_DSP4

# ---- A loop of two registered links: step 0 moves the one C register, and
# rule 2 drops the link into the cell first in name order. --------------------

stopped_block _loop
select -assert-count 2 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:PREG=1'b1 %i
select -assert-count 2 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 0 t:\$dff t:\$sdff t:\$dffe t:\$sdffe %u
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i

# ---- A stage in a mode that has no PCIN form: the finder does not look. ------

full_block _sub
stopped_block _sub
select -assert-count 2 t:QL_DSP4

full_block _acc_tail
stopped_block _acc_tail
select -assert-count 2 t:QL_DSP4

full_block _preadd_b
stopped_block _preadd_b
select -assert-count 2 t:QL_DSP4

# ---- An accumulating source, read through 40 bits into a 41-bit result. ------

own_file_block _acc_source dspv4_casc_acc_source.v
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000100101 %i

# ---- Accumulating loops, each from a file of its own, _loop_acc last. ---------

own_file_block _loop_head_walk dspv4_casc_loop_head_walk.v
select -assert-count 3 t:QL_DSP4 r:CREG=1'b0 %i

own_file_block _loop_acc dspv4_casc_loop_acc.v
select -assert-count 2 t:QL_DSP4 r:CREG=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:PREG=1'b1 %i r:OPMODE=9'b000010101 %i
