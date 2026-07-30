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

# -----------------------------------------------------------------------------
# Helpers
#
# `select` cannot express "this cell has no R port", and a promotion that
# silently drops a port still satisfies a naive -assert-count. So the port-level
# checks parse an RTLIL dump instead.
# -----------------------------------------------------------------------------

# Dump the currently selected module to a file and return its text.
proc rtlil_dump {tag} {
    set path [test_output_path "${tag}.dump"]
    tee -q -o $path dump
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

# Port name -> connected signal, for every cell of type `celltype` in `txt`.
# Returns a list of dicts, one per matching cell, in dump order.
proc cell_connections {txt celltype} {
    set cells {}
    set inside 0
    set conns [dict create]
    foreach line [split $txt "\n"] {
        if {[regexp {^\s*cell\s+\\?(\S+)\s+(\S+)\s*$} $line -> ctype cname]} {
            if {$inside} { lappend cells $conns }
            set conns [dict create]
            set inside [expr {$ctype eq $celltype}]
            continue
        }
        if {$inside && [regexp {^\s*connect\s+\\(\S+)\s+(.+?)\s*$} $line -> port sig]} {
            dict set conns $port $sig
        }
        if {$inside && [regexp {^\s*end\s*$} $line]} {
            lappend cells $conns
            set conns [dict create]
            set inside 0
        }
    }
    if {$inside} { lappend cells $conns }
    return $cells
}

# Assert that every cell of type `celltype` connects exactly the ports in
# `expected` -- no more, no fewer.
proc assert_port_set {tag celltype expected} {
    set txt [rtlil_dump $tag]
    set cells [cell_connections $txt $celltype]
    if {[llength $cells] == 0} {
        error "assert_port_set ($tag): no $celltype cell found in dump"
    }
    foreach conns $cells {
        set got [lsort [dict keys $conns]]
        if {$got ne [lsort $expected]} {
            error "assert_port_set ($tag): $celltype has ports {$got}, expected {[lsort $expected]}"
        }
    }
}

# Assert that some cell of type `celltype` connects `port` to `signal`.
proc assert_port_connected {tag celltype port signal} {
    set txt [rtlil_dump $tag]
    foreach conns [cell_connections $txt $celltype] {
        if {[dict exists $conns $port] && [dict get $conns $port] eq $signal} {
            return
        }
    }
    error "assert_port_connected ($tag): no $celltype cell with $port connected to $signal"
}

# Assert that no cell of type `celltype` survives with a used (non-constant)
# reset -- i.e. the fabric fallback cells are gone.
proc assert_no_fabric_ffs {} {
    select -assert-count 0 t:dffre
    select -assert-count 0 t:sdffre
    select -assert-count 0 t:dffnre
    select -assert-count 0 t:sdffnre
}

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
select -assert-count 1 t:dff a:keep
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
select -assert-count 1 t:dffn a:keep
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
