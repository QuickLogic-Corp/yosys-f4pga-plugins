# ql_fp_owner with -synplify: a hierarchical Synplify netlist of LUTn and dffre primitives.
# Each primitive is owned by the user instance that holds it, and the table says synplify.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

read_verilog $::env(DESIGN_TOP).v
$PASS_NAME -family qlf_k6n10f -top top -synplify -no_abc9 -blif fp_owner_synplify.blif -owner_table fp_owner_synplify.json

set fh [open fp_owner_synplify.json r]
set table [read $fh]
close $fh

if {[string first {"front_end": "synplify",} $table] < 0} { error "the table does not name the synplify front end" }
foreach {name type owners} {
    u_a.l_and $lut  {[["u_a"]]}
    u_a.r_q   dffre {[["u_a"]]}
    u_b.l_and $lut  {[["u_b"]]}
    u_b.r_q   dffre {[["u_b"]]}
    l_xor     $lut  {[[]]}
} {
    set row "\"name\": \"$name\", \"type\": \"$type\", \"owners\": $owners, \"rule\": \"recorded\""
    if {[string first $row $table] < 0} { error "expected $type $name owned by $owners" }
}
foreach path {{["u_a"]} {["u_b"]}} {
    if {[string first "\"path\": $path, \"module\": \"leaf\"" $table] < 0} { error "instance $path missing from the tree" }
}
