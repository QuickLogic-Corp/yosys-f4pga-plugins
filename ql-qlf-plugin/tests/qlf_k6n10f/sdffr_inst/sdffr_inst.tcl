# io_sdffr / io_sdffnr primitive definition and direct instantiation --
# test-plan section 3 (REQ-A1, REQ-A2, REQ-A3, REQ-A5).
#
# Direct instantiation is the manual escape hatch and must work independently of
# ql_ioff promotion, with and without -ioff.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 3.1  Survives synthesis without -ioff.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top direct_sdffr
yosys cd direct_sdffr
stat
select -assert-count 1 t:io_sdffr

# -----------------------------------------------------------------------------
# 3.2  Unchanged with -ioff: the pass matches none of the four source cell
#      types, so a directly instantiated primitive is never touched.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top direct_sdffr -ioff
yosys cd direct_sdffr
stat
select -assert-count 1 t:io_sdffr

# 3.4  Port set is exactly {C, D, R, Q} -- no E (REQ-A3).
assert_port_set direct_sdffr io_sdffr {C D R Q}
assert_port_connected direct_sdffr io_sdffr R {\rst_n}

# -----------------------------------------------------------------------------
# 3.3  Negedge variant.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top direct_sdffnr -ioff
yosys cd direct_sdffnr
stat
select -assert-count 1 t:io_sdffnr
select -assert-count 0 t:io_sdffr
assert_port_set direct_sdffnr io_sdffnr {C D R Q}

# -----------------------------------------------------------------------------
# 3.5  The primitives carry abc9_flop and lib_whitebox like their siblings.
#      `read_verilog -lib` -- how synth_quicklogic reads cells_sim.v -- turns
#      lib_whitebox into the plain `whitebox` attribute, so that is what to
#      assert here.
# 3.6  ...and are *synchronous*: elaborating the behavioural model must yield
#      $dff, never $adff. This is the check that catches an accidental
#      `always @(posedge C or negedge R)` copy-paste from dffre, which would
#      otherwise pass every count-based assertion above.
# -----------------------------------------------------------------------------
design -reset
read_verilog -lib -specify -nomem2reg +/quicklogic/qlf_k6n10f/cells_sim.v
select -assert-mod-count 1 =A:abc9_flop =io_sdffr %i
select -assert-mod-count 1 =A:whitebox =io_sdffr %i
select -assert-mod-count 1 =A:abc9_flop =io_sdffnr %i
select -assert-mod-count 1 =A:whitebox =io_sdffnr %i

foreach cell {io_sdffr io_sdffnr} {
    design -reset
    read_verilog -specify +/quicklogic/qlf_k6n10f/cells_sim.v
    hierarchy -top $cell
    yosys proc
    opt_expr
    opt_clean
    stat
    # Synchronous reset: a clock-edge-only sensitivity list gives $dff + $mux.
    select -assert-count 1 t:\$dff
    select -assert-count 0 t:\$adff
    select -assert-count 0 t:\$adffe
    select -assert-count 0 t:\$aldff
    select -assert-count 0 t:\$dffsr
}
