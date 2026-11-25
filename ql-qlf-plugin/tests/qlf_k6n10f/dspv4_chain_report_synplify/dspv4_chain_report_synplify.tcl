# dspv4_chain_report_synplify -- chains on the -synplify path, which the chain
# length line counts. One block per input, each with its own logs; the
# Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

# The whole flow. The log is <name>.log.
proc full_block {name top file} {
    global PASS_NAME LIB
    design -reset
    read_verilog $file
    tee -o $name.log $PASS_NAME -family qlf_k6n10f -top $top -synplify -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $top
    check -assert
}

# The map_dsp steps of the flow, up to the chain report, so the QL_DSP4 cells
# it reads can be dumped beside its line. The log is <name>_cells.log.
proc cells_block {name top file} {
    global PASS_NAME LIB
    design -reset
    read_verilog $file
    $PASS_NAME -family qlf_k6n10f -top $top -synplify -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    tee -o ${name}_cells.log ql_dspv2_to_dspv4
    ql_dsp4_check
    tee -a ${name}_cells.log ql_dsp4_chain_report
    tee -a ${name}_cells.log dump t:QL_DSP4
    yosys cd $top
    check -assert
}

# ---- Synplify's netlist of cascade_shared_1reg_regout_regout: QL_DSP4 cells
# already, ma1 -> cc -> ma2 on PCIN and ma3 on C. The bridge makes no cell. ---

full_block _direct_cells cascade_shared_1reg_regout_regout cascade_shared_1reg_regout_regout.vm
cells_block _direct_cells cascade_shared_1reg_regout_regout cascade_shared_1reg_regout_regout.vm
select -assert-count 4 t:QL_DSP4
select -assert-count 4 t:QL_DSP4 n:*.inst_dsp %i
select -assert-count 2 t:QL_DSP4 %co1:+\[PCOUT\] w:* %i %co1:+\[PCIN\] t:QL_DSP4 %i
select -assert-count 1 t:QL_DSP4 %co1:+\[PCOUT\] w:* %i %co1:+\[PCIN\] t:QL_DSP4 %i n:cc_p_reg_2_0_35_0_.inst_dsp %i
select -assert-count 1 t:QL_DSP4 %co1:+\[PCOUT\] w:* %i %co1:+\[PCIN\] t:QL_DSP4 %i n:ma2_mul_reg_2_0_35_0_.inst_dsp %i

# ---- Two QL_DSPV2 cells: the bridge makes both QL_DSP4 cells and the link. --
# 000010101 is MULT_ADD, whose Z reads PCIN; 000000101 is MULT.

full_block _bridge_pair _bridge_pair dspv4_chain_report_synplify.v
cells_block _bridge_pair _bridge_pair dspv4_chain_report_synplify.v
select -assert-count 0 t:QL_DSPV2
select -assert-count 2 t:QL_DSP4
select -assert-count 1 t:QL_DSP4 r:OPMODE=9'b000000101 %i
select -assert-count 1 t:QL_DSP4 %co1:+\[PCOUT\] w:* %i %co1:+\[PCIN\] t:QL_DSP4 %i r:OPMODE=9'b000010101 %i
