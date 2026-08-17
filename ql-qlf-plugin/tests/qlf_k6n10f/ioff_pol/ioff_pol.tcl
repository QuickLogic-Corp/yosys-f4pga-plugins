# Refusal cases and reset-polarity gating -- test-plan sections 5 and 5A
# (REQ-B2, REQ-B6, REQ-B7, REQ-B9, REQ-B10, REQ-B11).
#
# 5A.7 and 5A.8 are the load-bearing cases: they are where rule R1 disagrees
# with the alternatives that were rejected, so they are what stops a future
# refactor from silently drifting to a different rule.
#
# NOTE ON K. Rule R1 only declines when the shared-inverter override is off, and
# the shipped default is now K=1, which disables the rule entirely. Every case
# below that expects a *decline* therefore pins `-ioff_min_shared_reset 0`
# explicitly rather than relying on the default -- otherwise the test silently
# stops exercising R1 the next time the default moves.

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

# 5.8  The four refusal reasons are separately greppable (REQ-B6, defect D4:
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
# Section 5A -- reset polarity (rule R1)
# =============================================================================

# 5A.1  Active-low port reset: promoted, R wired straight to the port.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_lo -ioff
yosys cd rst_lo
stat
select -assert-count 1 t:io_sdffr
assert_port_connected rst_lo io_sdffr R {\rst_n}
assert_no_inverter_on_reset rst_lo

# 5A.2  Active-high port reset: declined, register stays in the CLB.
# 5A.10 The refusal is user-visible on the *normal* log, not only under -d, and
#       is polarity-specific rather than the old generic message.
design -load read
set log_hi [capture_log rst_hi synth_quicklogic -family qlf_k6n10f -top rst_hi -ioff -ioff_min_shared_reset 0]
yosys cd rst_hi
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre
assert_log_has rst_hi $log_hi "the reset is active-high"
assert_log_has rst_hi $log_hi "Use an active-low reset"
assert_log_lacks rst_hi $log_hi "E or R is used"

# 5A.3  Negedge variant of 5A.2.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_hi_n -ioff -ioff_min_shared_reset 0
yosys cd rst_hi_n
stat
select -assert-count 0 t:io_sdffnr
select -assert-count 1 t:sdffnre

# 5A.4  Active-low reset on an output-side register: promoted.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_lo_out -ioff
yosys cd rst_lo_out
stat
select -assert-count 1 t:io_sdffr
select -assert-count 1 t:io_sdffr a:keep %i
assert_port_connected rst_lo_out io_sdffr R {\rst_n}
assert_no_inverter_on_reset rst_lo_out

# 5A.5  Active-high reset on an output-side register: declined. Nothing is built
#       and the output port is not swapped -- so no cell carries `keep`.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_hi_out -ioff -ioff_min_shared_reset 0
yosys cd rst_hi_out
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre
select -assert-count 0 a:keep
select -assert-count 1 o:q_o

# 5A.6  Resetless: the polarity rule must not touch this path (REQ-B11). The
#       target is io_sdffr because this library defines it -- see ioff.tcl -- and
#       its R is tied inactive, which is precisely why R1 has nothing to weigh.
design -load read
synth_quicklogic -family qlf_k6n10f -top resetless -ioff -ioff_min_shared_reset 0
yosys cd resetless
stat
select -assert-count 1 t:io_sdffr
select -assert-count 0 t:dff
assert_all_ports_connected resetless io_sdffr R {1'1}

# 5A.7  Active-high reset from fabric logic: the inversion is absorbed into the
#       reset-expression LUT mask, so it is free and the register promotes.
#       This is the R1-vs-R2 discriminator.
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_hi_expr -ioff
yosys cd rst_hi_expr
stat
select -assert-count 1 t:io_sdffr
assert_no_inverter_on_reset rst_hi_expr

# 5A.8  Active-low reset from fabric logic: structurally identical to 5A.7 apart
#       from the LUT mask, and must also promote. Confirms the predicate is not
#       keying on "driver is a LUT".
design -load read
synth_quicklogic -family qlf_k6n10f -top rst_lo_expr -ioff
yosys cd rst_lo_expr
stat
select -assert-count 1 t:io_sdffr
assert_no_inverter_on_reset rst_lo_expr
