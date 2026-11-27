# ql_fp_owner -tree: a netlist flattened before Yosys read it has no hdlname or scopename,
# so every atom goes to top. It warns when the cell names still hold dotted paths, and only
# then.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

proc run_tree {name lut0 lut1} {
    set fh [open $name.il w]
    puts $fh "module \\top
  wire input 1 \\a
  wire output 2 \\o
  wire \\n
  cell \$lut \\$lut0
    parameter \\WIDTH 1
    parameter \\LUT 2'01
    connect \\A \\a
    connect \\Y \\n
  end
  cell \$lut \\$lut1
    parameter \\WIDTH 1
    parameter \\LUT 2'01
    connect \\A \\n
    connect \\Y \\o
  end
end"
    close $fh
    design -reset
    read_rtlil $name.il
    hierarchy -top top
    ql_fp_owner -tree
}

logger -expect warning {2 cell name\(s\) contain a dot \(e\.g\. u_a\.l0\)} 1
run_tree fp_owner_flat_dotted u_a.l0 u_b.u_c.l1
run_tree fp_owner_flat_plain l0 l1
logger -check-expected
