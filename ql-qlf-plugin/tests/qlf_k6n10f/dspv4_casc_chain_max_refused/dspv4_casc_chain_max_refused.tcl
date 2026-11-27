# dspv4_casc_chain_max_refused -- a -chain_max value that is not a plain
# non-negative integer stops the run with an error naming the option and the
# value. Both entry points are checked: synth_ql (even when it runs no DSP
# pass) and ql_dspv4. Each refusal is written to refused.log; the Makefile's
# verify line reads it.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_casc_chain_max_refused.v
hierarchy -top top

set refused [open refused.log w]
proc refuse {entry value command} {
    global refused
    if { ![catch {uplevel #0 $command} message] } {
        puts $refused "ACCEPTED $entry '$value'"
    } else {
        puts $refused "REFUSED $entry '$value': $message"
    }
}

foreach value {twelve -4 12abc {} {1 2} 99999999999} {
    refuse synth_ql $value [list $PASS_NAME -family qlf_k6n10f -top top -dspv4 -no_dsp -no_abc9 -chain_max $value -lib_path $LIB/]
    refuse ql_dspv4 $value [list ql_dspv4 -chain_max $value]
}
close $refused
