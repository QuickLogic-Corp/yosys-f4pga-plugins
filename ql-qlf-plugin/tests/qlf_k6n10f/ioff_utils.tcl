# Shared helpers for the ql_ioff / io_sdffr testcases.
#
# Sourced as ../ioff_utils.tcl from tests/qlf_k6n10f/ioff*/.
#
# `select` cannot express "this cell has no R port", and a promotion that
# silently drops a port still satisfies a naive -assert-count. The port-level
# checks therefore parse an RTLIL dump.

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

# Assert that every cell of type `celltype` connects `port` to `signal`.
proc assert_all_ports_connected {tag celltype port signal} {
    set txt [rtlil_dump $tag]
    set cells [cell_connections $txt $celltype]
    if {[llength $cells] == 0} {
        error "assert_all_ports_connected ($tag): no $celltype cell found in dump"
    }
    foreach conns $cells {
        if {![dict exists $conns $port]} {
            error "assert_all_ports_connected ($tag): $celltype has no $port port"
        }
        if {[dict get $conns $port] ne $signal} {
            error "assert_all_ports_connected ($tag): $celltype $port is\
                   [dict get $conns $port], expected $signal"
        }
    }
}

# Assert that no fabric fallback FF cell survives in the current module.
proc assert_no_fabric_ffs {} {
    select -assert-count 0 t:dffre
    select -assert-count 0 t:sdffre
    select -assert-count 0 t:dffnre
    select -assert-count 0 t:sdffnre
}
