# BLIF acceptance evidence -- test-plan section 7 (REQ-A3, REQ-C4).
#
# VPR resolves .subckt against the architecture's <model> by name, so a wrong
# cell name or an extra port synthesizes cleanly and then fails deep in packing.
# Checking the BLIF text here is the cheapest place to catch that.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

# Return the .subckt line naming `cell` from the BLIF at `path`.
proc blif_subckt {path cell} {
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    foreach line [split $txt "\n"] {
        if {[regexp "^\\.subckt\\s+$cell\\s" $line]} {
            return $line
        }
    }
    return ""
}

proc blif_text {path} {
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 7.1, 7.3, 7.4, 7.7, 7.8  io_sdffr in the BLIF, with exactly the arch model's
# port set {C, D, R, Q} bound to real nets.
# -----------------------------------------------------------------------------
set blif_r [test_output_path "ioff_sdffr.blif"]
design -load read
synth_quicklogic -family qlf_k6n10f -top blif_sdffr -ioff -blif $blif_r

set line [blif_subckt $blif_r io_sdffr]
if {$line eq ""} {
    error "7.1: BLIF has no `.subckt io_sdffr` line"
}

# 7.3  All four formals present, and no E= formal -- the arch model declares no
#      enable, so an extra port is a hard mismatch.
foreach formal {C= D= R= Q=} {
    if {![string match "*$formal*" $line]} {
        error "7.3: `.subckt io_sdffr` line lacks $formal: $line"
    }
}
if {[string match "*E=*" $line]} {
    error "7.3: `.subckt io_sdffr` line carries an E= formal: $line"
}

# 7.4  R names the reset net, not a constant or an unconnected literal.
if {![string match "*R=rst_n*" $line]} {
    error "7.4: io_sdffr R= is not bound to the reset net: $line"
}

# 7.6  No sdffre left behind for the promoted register.
assert_log_lacks ioff_sdffr [blif_text $blif_r] ".subckt sdffre"

# 7.5  Model declarations: exactly as for sdffre today, which is to say the
#      cell gets no separate .model block -- only the top module does. Asserting
#      the *consistency* is the point; an io_sdffr .model appearing here when
#      sdffre gets none would be the surprise.
set blif_base [test_output_path "ioff_base.blif"]
design -load read
synth_quicklogic -family qlf_k6n10f -top blif_sdffr -blif $blif_base
assert_log_has  ioff_base [blif_text $blif_base] ".subckt sdffre"
assert_log_lacks ioff_base [blif_text $blif_base] ".model sdffre"
assert_log_lacks ioff_sdffr [blif_text $blif_r] ".model io_sdffr"

# -----------------------------------------------------------------------------
# 7.2  The negedge variant emits io_sdffnr, lowercase, same port set.
# -----------------------------------------------------------------------------
set blif_n [test_output_path "ioff_sdffnr.blif"]
design -load read
synth_quicklogic -family qlf_k6n10f -top blif_sdffnr -ioff -blif $blif_n

set line_n [blif_subckt $blif_n io_sdffnr]
if {$line_n eq ""} {
    error "7.2: BLIF has no `.subckt io_sdffnr` line"
}
foreach formal {C= D= R= Q=} {
    if {![string match "*$formal*" $line_n]} {
        error "7.2: `.subckt io_sdffnr` line lacks $formal: $line_n"
    }
}
if {[string match "*E=*" $line_n]} {
    error "7.2: `.subckt io_sdffnr` line carries an E= formal: $line_n"
}
assert_log_lacks ioff_sdffnr [blif_text $blif_n] ".subckt sdffnre"

log "BLIF check: $line"
log "BLIF check: $line_n"
