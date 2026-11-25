# dspv4_chain_report -- chains the chain length line counts. One block per
# module, each with its own logs; the Makefile's verify line reads the logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_chain_report.v
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

# The map_dsp steps of the flow, up to the chain report, so the QL_DSP4 cells
# it reads can be dumped beside its line. The log is <name>_cells.log.
proc cells_block {name flags} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -run :map_dsp -lib_path $LIB/
    wreduce t:\$mul
    ql_dspv4 {*}$flags
    techmap -map +/mul2dsp.v -D DSP_A_MAXWIDTH=32 -D DSP_B_MAXWIDTH=18 -D DSP_A_MINWIDTH=2 -D DSP_B_MINWIDTH=2 -D DSP_SIGNEDONLY -D DSP_NAME=\$__QL_DSP4_MUL
    chtype -set \$mul t:\$__QL_DSP4_MUL
    select a:mul2dsp
    setattr -unset mul2dsp
    opt_expr -fine
    wreduce
    select -clear
    ql_dspv4 {*}$flags
    chtype -set \$mul t:\$__soft_mul
    ql_dspv2_to_dspv4
    ql_dsp4_check
    tee -o ${name}_cells.log ql_dsp4_chain_report
    tee -a ${name}_cells.log dump t:QL_DSP4
    yosys cd $name
    check -assert
}

# QL_DSP4 cells wired by hand, and the chain report called on them alone.
# debug adds the report's line for each chain it counts.
proc by_hand_block {name file} {
    design -reset
    read_verilog $file
    hierarchy -top $name
    tee -o $name.log debug ql_dsp4_chain_report
    check -assert
}

# ---- One multiply, no link. ---------------------------------------------------

full_block _none {}
cells_block _none {}
select -assert-count 1 t:QL_DSP4

# ---- Two stages, one link. ----------------------------------------------------

full_block _two {-chain_max 2}
cells_block _two {-chain_max 2}
select -assert-count 2 t:QL_DSP4

# ---- A wide multiply's two pieces, one PCIN >> 17 link. -----------------------

full_block _pcin17 {}
cells_block _pcin17 {}
select -assert-count 2 t:QL_DSP4

# ---- A PCIN >> 17 link above a plain link: one chain of three. ----------------

full_block _mixed_at_cap {-chain_max 3}
cells_block _mixed_at_cap {-chain_max 3}
select -assert-count 3 t:QL_DSP4

# ---- Two readers of one source: two chains of two at -chain_max 2, one chain
# of three at -chain_max 3. -----------------------------------------------------

full_block _two_readers {-chain_max 2}
cells_block _two_readers {-chain_max 2}
select -assert-count 4 t:QL_DSP4

full_block _two_readers_at_cap {-chain_max 3}
cells_block _two_readers_at_cap {-chain_max 3}
select -assert-count 4 t:QL_DSP4

# ---- Cells wired by hand: a chain of three and a chain of two. ----------------

by_hand_block _by_hand dspv4_chain_report_by_hand.v

# ---- No PCIN reads a PCOUT: no link. ------------------------------------------

by_hand_block _not_pcout dspv4_chain_report_by_hand.v

# ---- A constant on a PCOUT is not a source: no link. --------------------------

# No hierarchy pass and no check -assert: both reject a constant on an output
# port, the shape this block needs. The selection leaves the file's other
# modules out.
design -reset
read_verilog dspv4_chain_report_by_hand.v
tee -o _constant_pcout.log debug ql_dsp4_chain_report _constant_pcout
tee -a _constant_pcout.log dump _constant_pcout/t:QL_DSP4

# ---- A PCOUT read by a cell that is not a QL_DSP4: no link. ------------------

by_hand_block _not_dsp_reader dspv4_chain_report_by_hand.v
select -assert-count 1 t:QL_DSP4 %co1:+\[PCOUT\] w:* %i %co1:+\[PCIN\] t:OTHER_CELL %i

# ---- A PCIN that reads a cell that is not a QL_DSP4: no link. ----------------

by_hand_block _not_dsp_source dspv4_chain_report_by_hand.v
select -assert-count 1 t:OTHER_SOURCE %co1:+\[PCOUT\] w:* %i %co1:+\[PCIN\] t:QL_DSP4 %i

# ---- Two modules, nothing selected: the counts add up. With only the first
# module selected, only its chain is counted. No hierarchy pass, since that
# would delete the second module. ------------------------------------------------

design -reset
read_verilog dspv4_chain_report_two_modules.v
tee -o _two_modules.log debug ql_dsp4_chain_report
tee -o _two_modules_first.log debug ql_dsp4_chain_report _two_modules_three
check -assert
