# Baseline lock for the ql_ioff pass -- test-plan section 2.
#
# ql_ioff had zero test coverage. This file pins the pre-existing resetless
# promotion behaviour (REQ-B5, REQ-B11, REQ-C6) so the restructure that adds
# io_sdffr support cannot change it silently (RSK-2).
#
# Pass criterion is *identical cell counts* before and after that change, not
# merely "still promotes".

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 2.1  Input-side resetless FF promotes to `dff`, with E and R dropped.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_in -ioff
yosys cd resetless_in
stat
select -assert-count 1 t:dff
select -assert-count 0 t:dffn
assert_no_fabric_ffs
# REQ-B5: both E and R are dropped by the resetless path.
assert_port_set resetless_in dff {C D Q}
assert_port_connected resetless_in dff D {\pad_in}

# -----------------------------------------------------------------------------
# 2.2  Negedge variant promotes to `dffn`.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_in_n -ioff
yosys cd resetless_in_n
stat
select -assert-count 1 t:dffn
select -assert-count 0 t:dff
assert_no_fabric_ffs
assert_port_set resetless_in_n dffn {C D Q}

# -----------------------------------------------------------------------------
# 2.3  Output-side resetless FF promotes to a fresh `dff` carrying `keep`,
#      with the top-level output port name moved onto the new wire.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_out -ioff
yosys cd resetless_out
stat
select -assert-count 1 t:dff
select -assert-count 1 t:dff a:keep %i
assert_no_fabric_ffs
assert_port_set resetless_out dff {C D Q}
# The promoted cell drives the wire that now carries the output port name.
assert_port_connected resetless_out dff Q {\q_o}

# -----------------------------------------------------------------------------
# 2.4  Negedge output-side variant promotes to `dffn`.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_out_n -ioff
yosys cd resetless_out_n
stat
select -assert-count 1 t:dffn
select -assert-count 1 t:dffn a:keep %i
assert_no_fabric_ffs
assert_port_set resetless_out_n dffn {C D Q}
assert_port_connected resetless_out_n dffn Q {\q_o}

# -----------------------------------------------------------------------------
# 2.5  Both boundary paths in one module promote independently.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_both -ioff
yosys cd resetless_both
stat
select -assert-count 2 t:dff
assert_no_fabric_ffs
assert_port_set resetless_both dff {C D Q}

# -----------------------------------------------------------------------------
# 2.6  Without -ioff nothing is promoted -- promotion is the only difference
#      the flag makes (REQ-C2, REQ-D1).
# -----------------------------------------------------------------------------
#      Note the fabric fallback is `sdffre`, not `dffre`: dfflegalize for
#      qlf_k6n10f targets $_SDFFE_?N?P_, so even a resetless register arrives at
#      ql_ioff as a sync-reset cell with E and R tied to constant 1.
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_in
yosys cd resetless_in
stat
select -assert-count 0 t:dff
select -assert-count 1 t:sdffre
