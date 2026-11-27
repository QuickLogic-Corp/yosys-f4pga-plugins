# dspv4_casc_pcin17 -- shapes the pass links through PCIN >> 17: a wide
# multiply's two pieces, a PCIN >> 17 link above a plain link, and two readers
# of one source. One block per module, each with its own logs; the Makefile's
# verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_pcin17.v
design -save read

# The whole flow, with the options going through the wrapper. With none, the
# link is on by default.
proc full_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    tee -o $name.log $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 {*}$flags -lib_path $LIB/
    yosys cd $name
    check -assert
}

# The flow stopped before the leaf techmap, so the QL_DSP4 cells can still be
# read. The pieces exist only after mul2dsp, so this runs the map_dsp steps
# up to the second pass call, with `flags` forwarded to both ql_dspv4 calls.
# The log is <name>_cells.log.
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

# ---- Two pieces, one link. 001010101 is MULT_ADD_PCIN17, 000000101 is MULT. --

full_block _pcin17 {}
stopped_block _pcin17 {}
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i
# The MULT_ADD_PCIN17 cell reads PCIN, has no C, and the MULT cell drives PCOUT.
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[C\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i

# ---- A PCIN >> 17 link above a plain link: three cells fit -chain_max 3. ----
# 000010101 is MULT_ADD.

full_block _mixed_at_cap {-chain_max 3}
stopped_block _mixed_at_cap {-chain_max 3}
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[C\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i

# ---- Two readers of p0 >>> 17, and x heads a plain link to y. At -chain_max 2
# x does not fit, so z takes p0's PCOUT and x reads p0 on C. 000110101 is
# MULT_ADD_C. ------------------------------------------------------------------

full_block _two_readers {-chain_max 2}
stopped_block _two_readers {-chain_max 2}
select -assert-count 4 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:z %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:x %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:p0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i

# ---- The same RTL at -chain_max 3: x fits and has the longer chain below it,
# so x takes p0's PCOUT and z reads p0 on C. -----------------------------------------

full_block _two_readers_at_cap {-chain_max 3}
stopped_block _two_readers_at_cap {-chain_max 3}
select -assert-count 4 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:x %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:z %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:p0 %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i

# ---- Two readers of p0 >>> 17, and z heads a plain link to y. Both fit
# -chain_max 4, and z has the longer chain below it, so z takes p0's PCOUT
# although x comes first in the RTL. ---------------------------------------------

full_block _longer_chain_later {-chain_max 4}
stopped_block _longer_chain_later {-chain_max 4}
select -assert-count 4 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:z %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:x %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:p0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i

# ---- Two readers of p0 >>> 17 with chains of one cell each: the first in name
# order, x, takes p0's PCOUT. ---------------------------------------------------

full_block _equal_chains {-chain_max 4}
stopped_block _equal_chains {-chain_max 4}
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[P\] w:x %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[P\] w:z %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:p0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i
