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

# Run a yosys command with debug logging captured to a file, and return the log
# text. Used to check that the refusal reasons are separately greppable.
proc debug_log {tag args} {
    set path [test_output_path "${tag}.dbg"]
    tee -q -o $path debug {*}$args
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

# Run a yosys command with its normal (non-debug) log captured to a file.
proc capture_log {tag args} {
    set path [test_output_path "${tag}.out"]
    tee -q -o $path {*}$args
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

# Assert `needle` appears literally in `txt`.
proc assert_log_has {tag txt needle} {
    if {[string first $needle $txt] < 0} {
        error "assert_log_has ($tag): log does not contain \"$needle\""
    }
}

# Assert `needle` does not appear in `txt`.
proc assert_log_lacks {tag txt needle} {
    if {[string first $needle $txt] >= 0} {
        error "assert_log_lacks ($tag): log unexpectedly contains \"$needle\""
    }
}

# Output nets of dedicated polarity inverters: $lut cells with WIDTH 1 and the
# mask 2'01 (lut[0]=1, lut[1]=0).
proc reset_inverter_nets {txt} {
    set inverter_nets {}
    set ctype ""
    set width ""
    set mask ""
    foreach line [split $txt "\n"] {
        if {[regexp {^\s*cell\s+\\?(\S+)\s+(\S+)\s*$} $line -> t n]} {
            set ctype $t
            set width ""
            set mask ""
            continue
        }
        if {$ctype ne {$lut}} { continue }
        regexp {^\s*parameter\s+\\WIDTH\s+(\S+)\s*$} $line -> width
        regexp {^\s*parameter\s+\\LUT\s+(\S+)\s*$} $line -> mask
        if {[regexp {^\s*connect\s+\\Y\s+(.+?)\s*$} $line -> ynet]} {
            if {$width eq "1" && $mask eq "2'01"} {
                lappend inverter_nets $ynet
            }
        }
    }

    return $inverter_nets
}

# Assert that no promoted IO FF has its R pin driven by a dedicated inverter.
# Holds where the inversion is absorbed into a reset-expression LUT mask, and is
# the assertion that would catch a regression re-admitting a separate inverter
# there.
proc assert_no_inverter_on_reset {tag} {
    set txt [rtlil_dump $tag]
    set inverter_nets [reset_inverter_nets $txt]

    foreach celltype {io_sdffr io_sdffnr} {
        foreach conns [cell_connections $txt $celltype] {
            if {![dict exists $conns R]} { continue }
            set r [dict get $conns R]
            if {[lsearch -exact $inverter_nets $r] >= 0} {
                error "assert_no_inverter_on_reset ($tag): promoted $celltype has R\
                       driven by a dedicated inverter ($r)"
            }
        }
    }
}

# The converse: assert some promoted IO FF has its R pin driven by a dedicated
# inverter. An active-high reset needs one wherever the register lands, since
# both sdffre and io_sdffr reset on !R, so promoting anyway costs only the route
# from the fabric inverter out to that site's lreset -- and reset is not a
# critical path. This assertion pins that the inverter is not treated as a
# reason to decline.
proc assert_inverter_on_reset {tag} {
    set txt [rtlil_dump $tag]
    set inverter_nets [reset_inverter_nets $txt]

    foreach celltype {io_sdffr io_sdffnr} {
        foreach conns [cell_connections $txt $celltype] {
            if {![dict exists $conns R]} { continue }
            if {[lsearch -exact $inverter_nets [dict get $conns R]] >= 0} {
                return
            }
        }
    }
    error "assert_inverter_on_reset ($tag): no promoted IO FF has R driven by a\
           dedicated inverter"
}

# Assert that no fabric fallback FF cell survives in the current module.
proc assert_no_fabric_ffs {} {
    select -assert-count 0 t:dffre
    select -assert-count 0 t:sdffre
    select -assert-count 0 t:dffnre
    select -assert-count 0 t:sdffnre
}
