# Shared-inverter override and the K knob -- test-plan section 5B
# (REQ-B12, REQ-B13, REQ-B14).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

# Synthesize `top` at threshold `k` and assert the exact split between promoted
# IO FFs and registers left in the fabric. Exact counts, not just presence: a
# partial promotion is the specific failure the all-or-nothing rule forbids.
proc check_share {top k expect_io expect_fabric} {
    design -load read
    synth_quicklogic -family qlf_k6n10f -top $top -ioff -ioff_min_shared_reset $k
    yosys cd $top
    select -assert-count $expect_io t:io_sdffr
    select -assert-count $expect_fabric t:sdffre
}

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 5B.1  Threshold behaviour. K=0 is the override off (pure rule R1); K=1 makes
#       the polarity rule a no-op, which is a meaningful sweep data point rather
#       than a degenerate one; K=9 is above the widest group here.
# -----------------------------------------------------------------------------
#                    top      K  io  fabric
# 5B.1a
check_share          share1   0   0   1
check_share          share2   0   0   2
check_share          share4   0   0   4
check_share          share8   0   0   8
# 5B.1b
check_share          share1   1   1   0
check_share          share2   1   2   0
check_share          share4   1   4   0
check_share          share8   1   8   0
# 5B.1c
check_share          share1   2   0   1
check_share          share2   2   2   0
check_share          share4   2   4   0
check_share          share8   2   8   0
# 5B.1d
check_share          share1   4   0   1
check_share          share2   4   0   2
check_share          share4   4   4   0
check_share          share8   4   8   0
# 5B.1e
check_share          share1   8   0   1
check_share          share2   8   0   2
check_share          share4   8   0   4
check_share          share8   8   8   0
# 5B.1f
check_share          share1   9   0   1
check_share          share2   9   0   2
check_share          share4   9   0   4
check_share          share8   9   0   8

# -----------------------------------------------------------------------------
# 5B.2a  Group integrity: at K=4 on share4 all four promote, never a partial
#        two-of-four. The exact counts in 5B.1 above already assert this, since
#        a partial promotion would show up as a 2/2 split.
# 5B.2b  Independent groups: a 2-candidate and a 4-candidate group on different
#        reset nets are judged separately, never pooled. At K=4 the 4-group
#        promotes and the 2-group does not -- if they were pooled, 6 >= 4 would
#        promote all six.
# -----------------------------------------------------------------------------
check_share          share_indep  0   0   6
check_share          share_indep  2   6   0
check_share          share_indep  4   4   2
check_share          share_indep  8   0   6

# -----------------------------------------------------------------------------
# 5B.2c  Counting rule: the inverter in share_count drives eight reset pins but
#        only three belong to promotable candidates. The group counts 3, so it
#        promotes at K=3 and declines at K=4. Using raw fan-out would have
#        promoted at K=8.
# -----------------------------------------------------------------------------
check_share          share_count  3   3   5
check_share          share_count  4   0   8
check_share          share_count  8   0   8

# -----------------------------------------------------------------------------
# 5B.5  The override does not reach past the case it was written for.
# -----------------------------------------------------------------------------
# 5B.5a  Resetless path is untouched by K.
#        K only gates the shared-inverter override, which needs a reset to apply
#        to, so a reset-less register promotes identically at every K. The target
#        is io_sdffr because this library defines it -- see ioff.tcl -- and its R
#        is tied inactive, which is what keeps it outside the override entirely.
foreach k {0 1 2 8} {
    design -load read
    synth_quicklogic -family qlf_k6n10f -top share_none -ioff -ioff_min_shared_reset $k
    yosys cd share_none
    select -assert-count 1 t:io_sdffr
    select -assert-count 0 t:dff
}

# 5B.5b  An absorbed inversion was never declined, so the override never applies
#        and the register promotes at every K.
foreach k {0 1 2 8} {
    design -load read
    synth_quicklogic -family qlf_k6n10f -top share_expr -ioff -ioff_min_shared_reset $k
    yosys cd share_expr
    select -assert-count 1 t:io_sdffr
}

# 5B.5c  An asynchronous reset outranks the override at any K.
foreach k {0 1 2 8} {
    design -load read
    synth_quicklogic -family qlf_k6n10f -top share_async -ioff -ioff_min_shared_reset $k
    yosys cd share_async
    select -assert-count 0 t:io_sdffr
    select -assert-count 4 t:dffre
}

# 5B.5d  A real enable outranks the override at any K.
foreach k {0 1 2 8} {
    design -load read
    synth_quicklogic -family qlf_k6n10f -top share_en -ioff -ioff_min_shared_reset $k
    yosys cd share_en
    select -assert-count 0 t:io_sdffr
    select -assert-count 4 t:sdffre
}

# -----------------------------------------------------------------------------
# 5B.3  Argument plumbing.
# -----------------------------------------------------------------------------
# 5B.3c  Default: no option given behaves as the shipped default, K=1, so the
#        override fires and the whole group promotes. K=0 -- the value that makes
#        the polarity rule decline -- is pinned explicitly by the sweep table
#        above (`check_share share8 0 0 8`), so that property survives the default
#        moving again.
design -load read
synth_quicklogic -family qlf_k6n10f -top share8 -ioff
yosys cd share8
select -assert-count 8 t:io_sdffr
select -assert-count 0 t:sdffre

# 5B.3e  -ioff_min_shared_reset without -ioff must not enable promotion behind
#        -ioff's back.
design -load read
synth_quicklogic -family qlf_k6n10f -top share8 -ioff_min_shared_reset 2
yosys cd share8
select -assert-count 0 t:io_sdffr
select -assert-count 8 t:sdffre

# 5B.3a  Pass level: ql_ioff accepts -min_shared_reset directly. execute() used
#        to discard its argument vector entirely.
design -load read
synth_quicklogic -family qlf_k6n10f -top share2
yosys cd share2
select -assert-count 2 t:sdffre
ql_ioff -min_shared_reset 2
opt_clean
select -assert-count 2 t:io_sdffr

# -----------------------------------------------------------------------------
# 5B.4  Reporting for the sweep. The per-group candidate count is the part that
#       makes a sweep informative: totals say which K won, group sizes say which
#       K would have changed anything.
# -----------------------------------------------------------------------------
design -load read
set log_k0 [capture_log share8_k0 synth_quicklogic -family qlf_k6n10f -top share8 -ioff -ioff_min_shared_reset 0]
assert_log_has share8_k0 $log_k0 "ql_ioff summary: K=0"
assert_log_has share8_k0 $log_k0 "io_sdffr=0"
assert_log_has share8_k0 $log_k0 "declined by reset polarity: 8 in 1 group(s)"
assert_log_has share8_k0 $log_k0 "8 candidate(s)"

design -load read
set log_k2 [capture_log share8_k2 synth_quicklogic -family qlf_k6n10f -top share8 -ioff -ioff_min_shared_reset 2]
assert_log_has share8_k2 $log_k2 "ql_ioff summary: K=2"
assert_log_has share8_k2 $log_k2 "io_sdffr=8"
assert_log_has share8_k2 $log_k2 "declined by reset polarity: 0 in 0 group(s)"
