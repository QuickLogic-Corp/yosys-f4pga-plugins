# ql_fp_owner golden ownership: which RTL instance owns each atom, and by which step of the
# rule (aurora2#1725 design.md 3.2).
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

read_verilog $::env(DESIGN_TOP).v
$PASS_NAME -family qlf_k6n10f -top top -blif fp_owner.blif -owner_table fp_owner.json

proc file_text {path} {
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}
set table [file_text fp_owner.json]

proc atom_row {name} {
    global table
    set quoted [string map {\\ \\\\ \[ \\\[ \] \\\] $ \\$ . \\.} $name]
    if {![regexp -line -- "\\{\"name\": \"$quoted\",.*\\}" $table row]} {
        error "no atom $name in the owner table"
    }
    return $row
}

proc assert_owner {name owners rule} {
    set row [atom_row $name]
    if {[string first "\"owners\": $owners, \"rule\": \"$rule\"" $row] < 0} {
        error "$name: expected owners $owners by $rule, got $row"
    }
}

# A LUT named after the top port it drives is still the leaf's.
assert_owner {c_$lut_Y} {[["u_leaf"]]} recorded
assert_owner {y_$lut_Y} {[["u_mid", "u_leaf"]]} recorded
assert_owner {gen[0].u.c_$lut_Y} {[["gen[0].u"]]} recorded
assert_owner {gen[1].u.c_$lut_Y} {[["gen[1].u"]]} recorded

# Every register of u_mid, and only those, is owned by u_mid.
set ffs [regexp -all -line -- {"type": "sdffre", "owners": \[\["u_mid"\]\]} $table]
if {$ffs != 4} { error "expected 4 registers owned by u_mid, found $ffs" }

# The merged cone gets one owner, not two and not top.
set merged [regexp -all -line -- {"type": "\$lut", "owners": \[\["u_m[01]"\]\], "rule": "recorded"} $table]
if {$merged != 1} { error "expected the merged LUT owned by one of u_m0/u_m1, found $merged rows" }
if {[regexp -line -- {"owners": \[\["u_m0"\], \["u_m1"\]\]} $table]} { error "a merged LUT lists two owners" }

# A BRAM is named after its memory by memory_libmap and keeps that memory's owner.
if {![regexp -line -- {"name": "u_ram\.mem[^"]*", "type": "TDP[^"]*", "owners": \[\["u_ram"\]\], "rule": "recorded"} $table]} {
    error "the BRAM of u_ram is not owned by u_ram"
}

# The tree before flatten, and the hash of the BLIF the table describes.
foreach path {{["u_leaf"]} {["u_mid"]} {["u_mid", "u_leaf"]} {["gen[0].u"]} {["u_m1"]}} {
    if {[string first "\"path\": $path," $table] < 0} { error "instance $path missing from the tree" }
}
regexp {"netlist_sha256": "([0-9a-f]+)"} $table -> table_sha
set blif_sha [lindex [exec sha256sum fp_owner.blif] 0]
if {$table_sha ne $blif_sha} { error "netlist_sha256 $table_sha is not the BLIF's $blif_sha" }
