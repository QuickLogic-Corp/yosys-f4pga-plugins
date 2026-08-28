# ql_io_translate -- test-plan section 7.
#
# The pass re-spells Synplify's IBUF_FF/OBUF_FF as the GPIO v3.0 IO subtile
# flip-flop. Which registers are IO FFs is Synplify's decision; the pass must
# preserve that set exactly, so the assertions below are about the translation
# being one-for-one and faithful, not about any promotion decision.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

# -----------------------------------------------------------------------------
# 7.1  With io_sdffr in the cell library, every IBUF_FF/OBUF_FF is translated.
# -----------------------------------------------------------------------------
design -reset
read_verilog -lib -specify -nomem2reg +/quicklogic/qlf_k6n10f/cells_sim.v
read_verilog $::env(DESIGN_TOP).v
hierarchy -top io_translate

select -assert-count 2 t:IBUF_FF
select -assert-count 2 t:OBUF_FF

ql_io_translate

# One cell out for every cell in, and nothing of the old type left behind.
select -assert-count 4 t:io_sdffr
select -assert-count 0 t:IBUF_FF
select -assert-count 0 t:OBUF_FF
# Posedge-only primitives, so the negedge variant must never be produced.
select -assert-count 0 t:io_sdffnr

# Ports are remapped O->Q and I->D, C is carried through, and the active-low
# reset is tied to constant 1 so it never fires.
assert_port_set io_translate io_sdffr {C D Q R}
assert_all_ports_connected io_translate io_sdffr R {1'1}
assert_port_connected io_translate io_sdffr D {\pad_in [0]}
assert_port_connected io_translate io_sdffr Q {\pad_out [0]}

# -----------------------------------------------------------------------------
# 7.2  Inert when the netlist has no IO FFs -- the case every aurora device
#      currently produces, since the templates set -disable_io_insertion 1.
# -----------------------------------------------------------------------------
design -reset
read_verilog -lib -specify -nomem2reg +/quicklogic/qlf_k6n10f/cells_sim.v
read_verilog $::env(DESIGN_TOP).v
hierarchy -top io_translate_none

ql_io_translate
select -assert-count 0 t:io_sdffr
select -assert-count 0 t:io_sdffnr

# -----------------------------------------------------------------------------
# 7.3  Without io_sdffr in the cell library the cells are left alone, so a v2.x
#      device still gets IBUF_FF -> dff from synplify_map.v as before.
# -----------------------------------------------------------------------------
design -reset
read_verilog $::env(DESIGN_TOP).v
hierarchy -top io_translate

ql_io_translate
select -assert-count 0 t:io_sdffr
select -assert-count 2 t:IBUF_FF
select -assert-count 2 t:OBUF_FF
