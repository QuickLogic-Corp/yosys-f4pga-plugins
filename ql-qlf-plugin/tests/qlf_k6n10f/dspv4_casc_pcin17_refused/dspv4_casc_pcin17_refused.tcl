# dspv4_casc_pcin17_refused -- shapes where the pass makes no PCIN >> 17 link.
# One block per module, each with its own logs; the Makefile's verify line
# reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_pcin17_refused.v
design -save read

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
# forwarded to both ql_dspv4 calls. The log is
# <name>_cells.log.
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

# Control words: 001010101 MULT_ADD_PCIN17, 000110101 MULT_ADD_C, 000010101
# MULT_ADD, 000000101 MULT.

# ---- -no_pcin17: the upper piece stays MULT_ADD_C and reads C. -------------

stopped_block _pcin17_off -no_pcin17
select -assert-count 2 t:QL_DSP4
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i

# ---- A source that reads PCIN itself: p1 keeps its link from p0, and p2
# reads p1 on C. ---------------------------------------------------------------

full_block _mixed {-chain_max 4}
stopped_block _mixed {-chain_max 4}
select -assert-count 3 t:QL_DSP4
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:p1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i

# ---- The plain link below a PCIN >> 17 link counts toward -chain_max: at 2,
# x keeps its plain link to y and reads p0 on C. -------------------------------

full_block _mixed_cap {-chain_max 2}
stopped_block _mixed_cap {-chain_max 2}
select -assert-count 3 t:QL_DSP4
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b001010101 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i %ci1:+\[PCIN\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] w:p0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[PCOUT\] w:* %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b000000101 %i %co1:+\[PCOUT\] w:* %i

# ---- A refused read gives the reason that stops it. ------------------------

stopped_block _unsigned_narrow {-chain_max 4}
stopped_block _unsigned_wide {-chain_max 4}
stopped_block _signed_narrow {-chain_max 4}
stopped_block _other_upper_bits {-chain_max 4}
