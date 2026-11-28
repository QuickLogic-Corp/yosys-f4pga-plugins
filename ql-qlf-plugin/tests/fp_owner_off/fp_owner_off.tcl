# Without -owner_table the flow must match the one before the owner table existed: no .cname
# lines in the BLIF and no owner attributes, even where BRAMs merge and DSP-V4 cells form.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }
set LIB [file normalize [file join [file dirname [info script]] .. ..]]

read_verilog $::env(DESIGN_TOP).v
$PASS_NAME -family qlf_k6n10f -top top -dspv4 -no_abc9 -lib_path $LIB/ -blif fp_owner_off.blif

set fh [open fp_owner_off.blif r]
set blif [read $fh]
close $fh

set cnames [regexp -all -line -- {^\.cname } $blif]
if {$cnames != 0} { error "found $cnames .cname lines without -owner_table" }
set brams [regexp -all -line -- {^\.subckt TDP36K} $blif]
if {$brams != 1} { error "expected the two memories merged into one TDP36K, found $brams" }
if {![regexp -line -- {^\.subckt QL_DSP4} $blif]} { error "no DSP-V4 cell in the BLIF" }

select -assert-none a:ql_owner
# Hard blocks keep their old names, not the RTL instance path (u_a., u_mac.) -owner_table adds.
select -assert-none t:TDP36K t:QL_DSP4* %u n:u_* %i
