# ql_fp_owner -guard: VPR names a .names block after its output net, then renames it from
# .cname, and aborts if the new name is taken. A cell whose name, as write_blif spells it,
# equals a net bit, a port or an out: pad must therefore be renamed before write_blif.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

# \n# is spelled n? by write_blif, the name of wire \n?; \w[1] is a bit of \w; \out:o is
# the pad VPR makes for output o.
set rtlil {
module \top
  wire input 1 \a
  wire input 2 \b
  wire output 3 \o
  wire \n?
  wire width 2 \w
  cell $lut \n#
    parameter \WIDTH 2
    parameter \LUT 4'1000
    connect \A { \b \a }
    connect \Y \n?
  end
  cell $lut \w[1]
    parameter \WIDTH 1
    parameter \LUT 2'01
    connect \A \n?
    connect \Y \w [0]
  end
  cell $lut \out:o
    parameter \WIDTH 2
    parameter \LUT 4'0110
    connect \A { \w [0] \b }
    connect \Y \o
  end
end
}
set fh [open fp_owner_clash.il w]
puts $fh $rtlil
close $fh
read_rtlil fp_owner_clash.il
hierarchy -top top
ql_fp_owner -guard
write_blif -param -cname -iname fp_owner_clash.blif

set fh [open fp_owner_clash.blif r]
set blif [read $fh]
close $fh
foreach expected {{n?$fp1} {out:o$fp2} {w[1]$fp3}} {
    if {[string first ".cname $expected\n" $blif] < 0} { error "expected cell $expected in\n$blif" }
}
foreach taken {n? out:o w[1]} {
    if {[string first ".cname $taken\n" $blif] >= 0} { error "cell $taken kept a taken name" }
}
