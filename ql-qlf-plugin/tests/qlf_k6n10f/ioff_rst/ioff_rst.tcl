# Promotion with a used reset -- test-plan section 4
# (REQ-B1, REQ-B3, REQ-B4, REQ-B7, REQ-B8).
#
# The R-connectivity checks (4.8/4.9) are the ones that actually matter: a
# promotion that silently drops R still satisfies `-assert-count 1 t:io_sdffr`.
# The output path is the higher-risk of the two, because its cell is built from
# scratch and so inherits nothing.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 4.1  Input-side posedge register promotes to io_sdffr, R preserved.
# 4.8  R net identity on the input path (in-place mutation).
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top in_sdffr -ioff
yosys cd in_sdffr
stat
select -assert-count 1 t:io_sdffr
assert_no_fabric_ffs
assert_port_set in_sdffr io_sdffr {C D R Q}
assert_port_connected in_sdffr io_sdffr R {\rst_n}
assert_port_connected in_sdffr io_sdffr D {\pad_in}

# -----------------------------------------------------------------------------
# 4.2  Negedge variant promotes to io_sdffnr.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top in_sdffnr -ioff
yosys cd in_sdffnr
stat
select -assert-count 1 t:io_sdffnr
select -assert-count 0 t:io_sdffr
assert_no_fabric_ffs
assert_port_set in_sdffnr io_sdffnr {C D R Q}
assert_port_connected in_sdffnr io_sdffnr R {\rst_n}

# -----------------------------------------------------------------------------
# 4.3  Output-side register promotes to a fresh io_sdffr carrying `keep`.
# 4.9  R net identity on the output path -- the port has to be *set* on a
#      freshly constructed cell, which is the easy thing to forget.
# 4.10 The top-level output port name survives on the replacement wire.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top out_sdffr -ioff
yosys cd out_sdffr
stat
select -assert-count 1 t:io_sdffr
select -assert-count 1 t:io_sdffr a:keep %i
select -assert-count 1 o:q_o
assert_no_fabric_ffs
assert_port_set out_sdffr io_sdffr {C D R Q}
assert_port_connected out_sdffr io_sdffr R {\rst_n}
assert_port_connected out_sdffr io_sdffr Q {\q_o}

# -----------------------------------------------------------------------------
# 4.4  Negedge output-side variant.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top out_sdffnr -ioff
yosys cd out_sdffnr
stat
select -assert-count 1 t:io_sdffnr
select -assert-count 1 t:io_sdffnr a:keep %i
select -assert-count 1 o:q_o
assert_no_fabric_ffs
assert_port_set out_sdffnr io_sdffnr {C D R Q}
assert_port_connected out_sdffnr io_sdffnr R {\rst_n}

# -----------------------------------------------------------------------------
# 4.5  Both boundary paths in one module.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top both_sdffr -ioff
yosys cd both_sdffr
stat
select -assert-count 2 t:io_sdffr
assert_no_fabric_ffs
assert_port_set both_sdffr io_sdffr {C D R Q}
# Both cells -- input-path and output-path -- must reference the same reset net.
assert_all_ports_connected both_sdffr io_sdffr R {\rst_n}

# -----------------------------------------------------------------------------
# 4.6  8-bit registered input port: all eight bits promote off one reset net.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top bus_sdffr -ioff
yosys cd bus_sdffr
stat
select -assert-count 8 t:io_sdffr
assert_no_fabric_ffs
assert_port_set bus_sdffr io_sdffr {C D R Q}
assert_all_ports_connected bus_sdffr io_sdffr R {\rst_n}

# -----------------------------------------------------------------------------
# 4.7  Mixed bus: bits 0 and 1 also feed fabric logic and stay in the CLB; the
#      remaining six promote, and the per-bit output-wire swap still connects
#      the unpromoted bits through.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top mixed_bus -ioff
yosys cd mixed_bus
stat
select -assert-count 6 t:io_sdffr
select -assert-count 2 t:sdffre
select -assert-count 1 o:q_o
select -assert-count 1 o:extra
assert_all_ports_connected mixed_bus io_sdffr R {\rst_n}

# -----------------------------------------------------------------------------
# Section 8 -- equivalence checking (REQ-C5), following tests/dffs.
#
# Confirms promotion did not silently change reset polarity or drop the reset
# altogether, which the structural checks above could in principle miss on a
# path they do not cover.
# -----------------------------------------------------------------------------
foreach top {in_sdffr in_sdffnr out_sdffr out_sdffnr both_sdffr bus_sdffr} {
    design -load read
    hierarchy -top $top
    yosys proc
    equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v \
        synth_quicklogic -family qlf_k6n10f -top $top -ioff
}
