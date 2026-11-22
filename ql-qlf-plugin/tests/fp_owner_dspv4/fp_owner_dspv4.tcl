# ql_fp_owner on the DSP-V4 path, which rewrites the BLIF after write_blif: the table must
# be bound to the final file, and the DSP leaves owned by the instance holding the multiply.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }
set LIB [file normalize [file join [file dirname [info script]] .. ..]]

read_verilog $::env(DESIGN_TOP).v
$PASS_NAME -family qlf_k6n10f -top top -dspv4 -no_abc9 -lib_path $LIB/ -blif fp_owner_dspv4.blif -owner_table fp_owner_dspv4.json

set fh [open fp_owner_dspv4.json r]
set table [read $fh]
close $fh

regexp {"netlist_sha256": "([0-9a-f]+)"} $table -> table_sha
set blif_sha [lindex [exec sha256sum fp_owner_dspv4.blif] 0]
if {$table_sha ne $blif_sha} { error "netlist_sha256 $table_sha is not the final BLIF's $blif_sha" }

set leaves [regexp -all -line -- {"type": "QL_DSP4_[A-Z0-9_]+", "owners": \[\["u_mac"\]\]} $table]
set all_leaves [regexp -all -line -- {"type": "QL_DSP4_[A-Z0-9_]+"} $table]
if {$all_leaves == 0} { error "no DSP-V4 leaf in the owner table" }
if {$leaves != $all_leaves} { error "$leaves of $all_leaves DSP-V4 leaves are owned by u_mac" }
