# ql_fp_owner with -rel_ip_blif: the linked IP's atoms are owned by the instance that holds
# them. That flow writes no .cname, so each atom is named after its output net, as VPR names it.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

proc file_text {path} {
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

read_verilog $::env(DESIGN_TOP).v
$PASS_NAME -family qlf_k6n10f -top top -rel_ip_blif rel_ip.eblif -blif fp_owner_rel_ip.blif -owner_table fp_owner_rel_ip.json

set table [file_text fp_owner_rel_ip.json]
set blif [file_text fp_owner_rel_ip.blif]

foreach {name type owners} {
    u_ip0.n_inv $lut   {[["u_ip0"]]}
    u_ip1.n_inv $lut   {[["u_ip1"]]}
    y0          dffre  {[["u_ip0"]]}
    y1          dffre  {[["u_ip1"]]}
    r           sdffre {[[]]}
} {
    set row "\"name\": \"$name\", \"type\": \"$type\", \"owners\": $owners,"
    if {[string first $row $table] < 0} { error "expected $type $name owned by $owners" }
}

if {[string first ".cname " $blif] >= 0} { error "the -rel_ip_blif BLIF has .cname lines" }
foreach {row name} [regexp -all -inline -line -- {"name": "([^"]+)", "type": "(?!\$const)} $table] {
    set quoted [string map {. \\. $ \\$ [ \\[ ] \\]} $name]
    if {![regexp -line -- "^\\.names .* $quoted\$|^\\.subckt .* Q=${quoted}( |\$)" $blif]} {
        error "atom $name of the table is not an output net of the BLIF"
    }
}

regexp {"netlist_sha256": "([0-9a-f]+)"} $table -> table_sha
set blif_sha [lindex [exec sha256sum fp_owner_rel_ip.blif] 0]
if {$table_sha ne $blif_sha} { error "netlist_sha256 $table_sha is not the BLIF's $blif_sha" }
