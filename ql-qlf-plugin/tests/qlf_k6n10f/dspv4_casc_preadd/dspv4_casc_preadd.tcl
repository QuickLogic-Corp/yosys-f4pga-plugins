# dspv4_casc_preadd -- pre-adder stages, (d + a) * b + prev, whose link is
# made, at -chain_max 12. One block per module, each with its own logs; the
# Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_preadd.v
design -save read

# Stop the flow before the leaf techmap, so the QL_DSP4 cells and the $add
# cells can still be read, then call the pass the way the flow would.
# -verbose names each link and each grouping decision. The log is <name>.log.
proc stopped_block {name} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o $name.log ql_dspv4 -chain_max 12 -verbose
    tee -a $name.log dump t:QL_DSP4
    yosys cd $name
    check -assert
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

# Control words: 000110101 MULT_ADD_C and PREADD_A_MULT_B_C, 000010101
# PREADD_A_MULT_B_CASC, 110010101 MULT_ADD_C_CASC. The pre-adder words also
# have INMODE 00100 and AMULTSEL 1; the others have INMODE 00000.

# ---- A MULT_ADD_C head, then three pre-adder stages: every link made. -------

full_block _preadd
stopped_block _preadd
select -assert-count 4 t:QL_DSP4
select -assert-count 3 t:QL_DSP4 r:OPMODE=9'b000010101 %i r:INMODE=5'b00100 %i r:AMULTSEL=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i r:INMODE=5'b00000 %i
select -assert-count 0 t:\$add

# ---- Three pre-adder stages: s2 holds the range of two pre-adder products. --

full_block _preadd_38
stopped_block _preadd_38
select -assert-count 3 t:QL_DSP4
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b000010101 %i r:INMODE=5'b00100 %i r:AMULTSEL=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i r:INMODE=5'b00100 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i %ci1:+\[C\] i:c0 %i

# ---- A pre-adder stage whose result a $add reads: the pre-adder cell links,
# and no grouping is tried on it, so the $add stays in fabric.

stopped_block _preadd_addend_g1
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i r:INMODE=5'b00100 %i r:AMULTSEL=1'b1 %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 1 t:\$add
select -assert-count 1 t:\$add %ci1:+\[A\] w:s %i
# s is an alias of the pre-adder cell's P; opt_clean names the P bits s.
opt_clean
select -assert-count 1 t:QL_DSP4 r:INMODE=5'b00100 %i %co1:+\[P\] w:s %i

# ---- The same with a MULT_ADD_C stage below: that stage takes the $add. -----

stopped_block _preadd_addend_mixed
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i r:INMODE=5'b00100 %i r:AMULTSEL=1'b1 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i r:INMODE=5'b00000 %i r:AMULTSEL=1'b0 %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i r:INMODE=5'b00000 %i
select -assert-count 0 t:\$add
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i %ci1:+\[C\] i:k %i
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b110010101 %i %ci1:+\[PCIN\] t:QL_DSP4 r:INMODE=5'b00100 %i %co1:+\[PCOUT\] %i
select -assert-count 1 t:QL_DSP4 r:INMODE=5'b00100 %i %ci1:+\[PCIN\] t:QL_DSP4 r:OPMODE=9'b000110101 %i %co1:+\[PCOUT\] %i
