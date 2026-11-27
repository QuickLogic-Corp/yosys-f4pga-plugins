# ql_fp_owner: an empty hdlname, which only a user attribute can give, names no scope. The
# cell falls back to the top owner instead of crashing the pass.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set rtlil {
module \top
  wire input 1 \a
  wire output 2 \o
  wire \n
  attribute \hdlname ""
  cell $lut \e
    parameter \WIDTH 1
    parameter \LUT 2'01
    connect \A \a
    connect \Y \n
  end
  attribute \hdlname "u_a l"
  cell $lut \l
    parameter \WIDTH 1
    parameter \LUT 2'01
    connect \A \n
    connect \Y \o
  end
end
}
set fh [open fp_owner_hdlname.il w]
puts $fh $rtlil
close $fh
read_rtlil fp_owner_hdlname.il
hierarchy -top top
ql_fp_owner -tree
ql_fp_owner -assign
write_rtlil fp_owner_hdlname.out.il

set fh [open fp_owner_hdlname.out.il r]
set out [read $fh]
close $fh
# The attributes written just before each cell. The top owner is the empty path, which
# set_string_attribute stores as no \ql_owner at all.
proc attrs_of {cell} {
    global out
    if {![regexp -- "((?:  attribute \[^\n\]*\n)*)  cell \\\$lut \\\\$cell\n" $out -> attrs]} {
        error "no cell $cell in\n$out"
    }
    return $attrs
}
set e [attrs_of e]
if {[string first {\ql_owner_rule "recorded"} $e] < 0 || [string first {\ql_owner "} $e] >= 0} {
    error "cell e: expected the top owner by recorded, got\n$e"
}
if {[string first {\ql_owner "u_a"} [attrs_of l]] < 0} { error "cell l: expected owner u_a" }
if {[string first "\\ql_fp_tree \"u_a\\t\\n\"" $out] < 0} { error "expected the tree to hold only u_a" }
