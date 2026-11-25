# dspv4_chain_report_loop -- PCIN loops the chain report does not count. One
# block per module, each with its own log; the Makefile's verify line reads the
# logs.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

# QL_DSP4 cells wired by hand, and the chain report called on them alone.
# debug adds the report's line for each chain it counts.
proc by_hand_block {name} {
    design -reset
    read_verilog dspv4_chain_report_loop.v
    hierarchy -top $name
    tee -o $name.log debug ql_dsp4_chain_report
    check -assert
}

# ---- Three cells in a ring: a warning for each, no chain. ---------------------

by_hand_block _loop3

# ---- A ring of two and a cell fed from it: a warning for each of the three. ---

by_hand_block _loop_tail

# ---- A ring of two beside a chain of two: the chain is still counted. ---------

by_hand_block _loop_beside
