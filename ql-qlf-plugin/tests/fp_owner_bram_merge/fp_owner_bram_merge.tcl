# ql_fp_owner on a merged BRAM: two 18K memories in two instances share one TDP36K, and its
# atom lists both instances as owners.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

read_verilog $::env(DESIGN_TOP).v
$PASS_NAME -family qlf_k6n10f -top top -blif fp_owner_bram_merge.blif -owner_table fp_owner_bram_merge.json

set fh [open fp_owner_bram_merge.json r]
set table [read $fh]
close $fh

set brams [regexp -all -line -- {"type": "TDP36K[^"]*"} $table]
if {$brams != 1} { error "expected the two memories merged into one TDP36K, found $brams" }
if {![regexp -line -- {"type": "TDP36K[^"]*", "owners": \[\["u_a"\], \["u_b"\]\], "rule": "recorded"} $table]} {
    regexp -line -- {.*"type": "TDP36K.*} $table row
    error "the merged BRAM does not list u_a and u_b as owners: $row"
}
