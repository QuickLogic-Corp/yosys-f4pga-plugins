# qlf_k6n10f has no latch cells: synth_ql must reject D latches rather than map them.
# log_error exits Yosys, so each case runs in its own process.

set design [file normalize $::env(DESIGN_TOP).v]
foreach top {my_latch my_latchn} {
    foreach opt {"" "-nosdff"} {
        set script "plugin -i ql-qlf; read_verilog $design; hierarchy -top $top; proc; synth_ql -family qlf_k6n10f -top $top $opt"
        if {![catch {exec yosys -q -p $script} out]} {
            error "synth_ql accepted a latch: $top $opt"
        }
        if {![string match "*D latches are not supported*" $out]} {
            error "$top $opt failed for another reason: $out"
        }
        puts "$top $opt: rejected as expected"
    }
}
