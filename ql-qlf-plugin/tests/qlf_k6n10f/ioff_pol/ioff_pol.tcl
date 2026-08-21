# Refusal cases and reset polarity -- test-plan sections 5 and 5A
# (REQ-B2, REQ-B6, REQ-B7, REQ-B10, REQ-B11).
#
# Reset polarity is NOT a refusal reason. Anything that can go on an IO tile
# goes: an active-high reset needs inverting wherever the register lands, since
# both sdffre and io_sdffr reset on !R, so promoting costs only the route from
# the fabric inverter out to that site's lreset -- and reset is not a critical
# path. Section 5A pins that, and 5A.2/5A.3/5A.5 are its load-bearing cases:
# they promote *with* the inverter present, so a refactor that reintroduced a
# polarity guard would fail them rather than silently shrink the feature.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

read_verilog $::env(DESIGN_TOP).v
design -save read

# =============================================================================
# Section 5 -- general refusals. Each must leave the register in the fabric.
# =============================================================================

# 5.1  Asynchronous reset is never promoted: the IO FF reset is synchronous.
design -load read
synth_quicklogic -family qlf_k6n10f -top async_rst -ioff
yosys cd async_rst
stat
select -assert-count 0 t:io_sdffr
select -assert-count 0 t:dff
select -assert-count 1 t:dffre

# 5.2  Negedge asynchronous variant.
design -load read
synth_quicklogic -family qlf_k6n10f -top async_rst_n -ioff
yosys cd async_rst_n
stat
select -assert-count 0 t:io_sdffnr
select -assert-count 0 t:dffn
select -assert-count 1 t:dffnre

# 5.3  A real clock enable disqualifies the candidate: no enable in the IO FF.
design -load read
synth_quicklogic -family qlf_k6n10f -top enabled -ioff
yosys cd enabled
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre

# 5.4  D has another consumer.
design -load read
synth_quicklogic -family qlf_k6n10f -top fanout_d -ioff
yosys cd fanout_d
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre

# 5.5  Output-side Q also feeds the fabric.
design -load read
synth_quicklogic -family qlf_k6n10f -top q_used -ioff
yosys cd q_used
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre

# 5.6  Not a boundary register at all.
design -load read
synth_quicklogic -family qlf_k6n10f -top not_boundary -ioff
yosys cd not_boundary
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre

# 5.7  Eligible on both paths: input promotion wins. The output path would have
#      set `keep` on a freshly built cell, so the absence of `keep` is what
#      distinguishes the two.
design -load read
synth_quicklogic -family qlf_k6n10f -top both_paths -ioff
yosys cd both_paths
stat
select -assert-count 1 t:io_sdffr
select -assert-count 0 t:io_sdffr a:keep %i

# 5.8  The three refusal reasons are separately greppable (REQ-B6, defect D4:
#      they used to be one "E or R is used" message).
design -load read
set log_async [debug_log async_rst synth_quicklogic -family qlf_k6n10f -top async_rst -ioff]
assert_log_has async_rst $log_async "asynchronous reset is used"

design -load read
set log_en [debug_log enabled synth_quicklogic -family qlf_k6n10f -top enabled -ioff]
assert_log_has enabled $log_en "E is used"
assert_log_lacks enabled $log_en "asynchronous reset is used"

design -load read
set log_fan [debug_log fanout_d synth_quicklogic -family qlf_k6n10f -top fanout_d -ioff]
assert_log_has fanout_d $log_fan "D has other consumers"

# =============================================================================
# Section 5A -- reset polarity
# =============================================================================

# 5A.1  Active-low port reset: promoted, R wired straight to the port.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_lo -ioff
yosys cd rst_lo
stat
select -assert-count 1 t:io_sdffr
assert_port_connected rst_lo io_sdffr R {\rst_n}
assert_no_inverter_on_reset rst_lo

# 5A.2  Active-high port reset: promoted anyway, with a dedicated inverter LUT
#       on the reset path. Nothing in the log may present the polarity as a
#       reason not to promote.
design -load read
set log_hi [capture_log rst_hi synth_quicklogic -family qlf_k6n10f -top rst_hi -ioff]
yosys cd rst_hi
stat
select -assert-count 1 t:io_sdffr
select -assert-count 0 t:sdffre
assert_inverter_on_reset rst_hi
assert_log_lacks rst_hi $log_hi "the reset is active-high"
assert_log_lacks rst_hi $log_hi "E or R is used"

# 5A.3  Negedge variant of 5A.2.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_hi_n -ioff
yosys cd rst_hi_n
stat
select -assert-count 1 t:io_sdffnr
select -assert-count 0 t:sdffnre
assert_inverter_on_reset rst_hi_n

# 5A.4  Active-low reset on an output-side register: promoted.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_lo_out -ioff
yosys cd rst_lo_out
stat
select -assert-count 1 t:io_sdffr
select -assert-count 1 t:io_sdffr a:keep %i
assert_port_connected rst_lo_out io_sdffr R {\rst_n}
assert_no_inverter_on_reset rst_lo_out

# 5A.5  Active-high reset on an output-side register: promoted too. The output
#       path builds a fresh cell and swaps the port, so `keep` is what shows the
#       promotion actually went down that path.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_hi_out -ioff
yosys cd rst_hi_out
stat
select -assert-count 1 t:io_sdffr
select -assert-count 1 t:io_sdffr a:keep %i
select -assert-count 0 t:sdffre
assert_inverter_on_reset rst_hi_out

# 5A.6  Resetless (REQ-B11). The target is io_sdffr because this library defines
#       it -- see ioff.tcl -- and its R is tied inactive, so no reset net and no
#       inverter exist on this path at all.
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless -ioff
yosys cd resetless
stat
select -assert-count 1 t:io_sdffr
select -assert-count 0 t:dff
assert_all_ports_connected resetless io_sdffr R {1'1}

# 5A.7  Active-high reset from fabric logic: the inversion is absorbed into the
#       reset-expression LUT mask, so no separate inverter is built -- unlike
#       5A.2, where the reset comes straight from a port.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_hi_expr -ioff
yosys cd rst_hi_expr
stat
select -assert-count 1 t:io_sdffr
assert_no_inverter_on_reset rst_hi_expr

# 5A.8  Active-low reset from fabric logic: structurally identical to 5A.7 apart
#       from the LUT mask, and must also promote with no separate inverter.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_lo_expr -ioff
yosys cd rst_lo_expr
stat
select -assert-count 1 t:io_sdffr
assert_no_inverter_on_reset rst_lo_expr
