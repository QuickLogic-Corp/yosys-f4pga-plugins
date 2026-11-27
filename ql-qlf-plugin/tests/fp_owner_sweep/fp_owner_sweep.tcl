# ql_fp_owner -write leaves out the atoms VPR sweeps: a block none of whose outputs has a sink,
# pass after pass. c_dead drives nothing; c_feed feeds only c_dead, so it goes on the next pass;
# c_live drives the top port and stays.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set rtlil {
module \adder_carry
  wire input 1 \cin
  wire input 2 \g
  wire input 3 \p
  wire output 4 \cout
  wire output 5 \sumout
end
attribute \top 1
module \top
  wire input 1 \a
  wire input 2 \b
  wire output 3 \o
  wire \chain
  wire \dead
  wire \nobody
  cell \adder_carry \c_live
    connect \cin \a
    connect \g \a
    connect \p \b
    connect \sumout \o
  end
  cell \adder_carry \c_feed
    connect \cin \b
    connect \g \a
    connect \p \b
    connect \cout \chain
  end
  cell \adder_carry \c_dead
    connect \cin \chain
    connect \g \a
    connect \p \b
    connect \sumout \nobody
  end
end
}
set fh [open fp_owner_sweep.il w]
puts $fh $rtlil
close $fh
read_rtlil fp_owner_sweep.il
hierarchy -top top
write_blif -param -cname -iname fp_owner_sweep.blif
ql_fp_owner -write fp_owner_sweep.json -blif fp_owner_sweep.blif

set fh [open fp_owner_sweep.json r]
set table [read $fh]
close $fh
if {[string first {"name": "c_live"} $table] < 0} { error "c_live, which drives a port, is not in the table" }
foreach gone {c_dead c_feed} {
    if {[string first "\"name\": \"$gone\"" $table] >= 0} { error "$gone, which VPR sweeps, is in the table" }
}
