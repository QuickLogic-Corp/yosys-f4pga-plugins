# Reset-less boundary promotion for the ql_ioff pass -- test-plan section 2.
#
# ql_ioff had zero test coverage. This file pins the reset-less promotion
# behaviour (REQ-B5, REQ-B11, REQ-C6) so it cannot change silently (RSK-2).
#
# NOTE ON THE EXPECTED TARGET. A reset-less boundary register used to promote to
# a plain `dff`/`dffn`. On a GPIO v3.0 cell library it now promotes to
# `io_sdffr`/`io_sdffnr` with the active-low reset tied to constant 1 instead.
# The reason is architectural: v3.0 collapsed the two v2.x IO flip-flops into
# one whose synchronous reset is hard-wired to io.lreset with no mux, so those
# architectures declare no dff/dffn model at all and a plain `dff` cannot be
# packed. ql_ioff keys off whether the cell library defines io_sdffr, and this
# family's library does -- hence the expectations below.
#
# The v2.x fallback (no io_sdffr in the library -> dff/dffn as before) is
# covered by ioff_v2x_fallback, which drives ql_ioff directly against a minimal
# library, and by the aurora flow tests running on v2.x devices.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 2.1  Input-side resetless FF promotes to `io_sdffr`, E dropped, R held off.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_in -ioff
yosys cd resetless_in
stat
select -assert-count 1 t:io_sdffr
select -assert-count 0 t:io_sdffnr
select -assert-count 0 t:dff
assert_no_fabric_ffs
# REQ-B5: E is dropped. R is kept but tied inactive -- the IO FF has no
# reset-less variant, so "no reset" is expressed as a reset that never fires.
assert_port_set resetless_in io_sdffr {C D Q R}
assert_all_ports_connected resetless_in io_sdffr R {1'1}
assert_port_connected resetless_in io_sdffr D {\pad_in}

# -----------------------------------------------------------------------------
# 2.2  Negedge variant promotes to `io_sdffnr`.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_in_n -ioff
yosys cd resetless_in_n
stat
select -assert-count 1 t:io_sdffnr
select -assert-count 0 t:io_sdffr
select -assert-count 0 t:dffn
assert_no_fabric_ffs
assert_port_set resetless_in_n io_sdffnr {C D Q R}
assert_all_ports_connected resetless_in_n io_sdffnr R {1'1}

# -----------------------------------------------------------------------------
# 2.3  Output-side resetless FF promotes to a fresh `io_sdffr` carrying `keep`,
#      with the top-level output port name moved onto the new wire.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_out -ioff
yosys cd resetless_out
stat
select -assert-count 1 t:io_sdffr
select -assert-count 1 t:io_sdffr a:keep %i
assert_no_fabric_ffs
assert_port_set resetless_out io_sdffr {C D Q R}
assert_all_ports_connected resetless_out io_sdffr R {1'1}
# The promoted cell drives the wire that now carries the output port name.
assert_port_connected resetless_out io_sdffr Q {\q_o}

# -----------------------------------------------------------------------------
# 2.4  Negedge output-side variant promotes to `io_sdffnr`.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_out_n -ioff
yosys cd resetless_out_n
stat
select -assert-count 1 t:io_sdffnr
select -assert-count 1 t:io_sdffnr a:keep %i
assert_no_fabric_ffs
assert_port_set resetless_out_n io_sdffnr {C D Q R}
assert_all_ports_connected resetless_out_n io_sdffnr R {1'1}
assert_port_connected resetless_out_n io_sdffnr Q {\q_o}

# -----------------------------------------------------------------------------
# 2.5  Both boundary paths in one module promote independently.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless_both -ioff
yosys cd resetless_both
stat
select -assert-count 2 t:io_sdffr
assert_no_fabric_ffs
assert_port_set resetless_both io_sdffr {C D Q R}
assert_all_ports_connected resetless_both io_sdffr R {1'1}

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
select -assert-count 0 t:io_sdffr
select -assert-count 0 t:io_sdffnr
select -assert-count 1 t:sdffre
