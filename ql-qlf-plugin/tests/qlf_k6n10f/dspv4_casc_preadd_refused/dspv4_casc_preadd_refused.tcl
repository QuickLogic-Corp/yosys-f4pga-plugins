# dspv4_casc_preadd_refused -- pre-adder stages whose link is refused, or
# that have no link to make, at -chain_max 12. One block per module, each with
# its own logs; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_preadd_refused.v
design -save read

# Stop the flow before the leaf techmap, so the QL_DSP4 cells and the $add
# cells can still be read, then call the pass the way the flow would.
# -verbose names each link and each refusal. The log is <name>.log.
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

# ---- s2 one bit short of two pre-adder products: its link stays on C. -------

full_block _preadd_37
stopped_block _preadd_37
select -assert-count 3 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000010101 %i r:INMODE=5'b00100 %i r:AMULTSEL=1'b1 %i
select -assert-count 2 t:QL_DSP4 r:OPMODE=9'b000110101 %i r:INMODE=5'b00100 %i
select -assert-count 1 t:QL_DSP4 %ci1:+\[C\] w:s2 %i

# ---- C is a fabric $add's sum, not a cell's result: no link, no grouping. ---

stopped_block _preadd_addend_g2
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000110101 %i r:INMODE=5'b00100 %i r:AMULTSEL=1'b1 %i
select -assert-count 0 t:QL_DSP4 r:OPMODE=9'b110010101 %i
select -assert-count 1 t:\$add
select -assert-count 1 t:\$add %co1:+\[Y\] t:QL_DSP4 r:INMODE=5'b00100 %i %ci1:+\[C\] %i
