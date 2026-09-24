yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

# The shipped k6n10f cells_sim.v marks adder_carry (* blackbox *), which equiv_opt cannot map through.
set fh [open [file join [exec yosys-config --datdir] quicklogic qlf_k6n10f cells_sim.v]]
set k6n10f_sim [regsub -all {\(\* blackbox \*\)\n} [read $fh] {}]
close $fh
set k6n10f_sim_file [test_output_path "k6n10f_cells_sim.v"]
set fh [open $k6n10f_sim_file w]
puts -nonewline $fh $k6n10f_sim
close $fh

# Equivalence check for adder synthesis for qlf-k6n10f
read_verilog -icells -DWIDTH=4 $::env(DESIGN_TOP).v
hierarchy -check -top full_adder
yosys proc
equiv_opt -assert  -map $k6n10f_sim_file synth_ql -family qlf_k6n10f
design -load postopt
yosys cd full_adder
stat
select -assert-count 5 t:adder_carry

design -reset

# Equivalence check for subtractor synthesis for qlf-k6n10f
read_verilog -icells -DWIDTH=4 $::env(DESIGN_TOP).v
hierarchy -check -top subtractor
yosys proc
equiv_opt -assert  -map $k6n10f_sim_file synth_ql -family qlf_k6n10f
design -load postopt
yosys cd subtractor
stat
select -assert-count 5 t:adder_carry

design -reset

# Equivalence check for comparator synthesis for qlf-k6n10f
read_verilog -icells -DWIDTH=4 $::env(DESIGN_TOP).v
hierarchy -check -top comparator
yosys proc
equiv_opt -assert  -map $k6n10f_sim_file synth_ql -family qlf_k6n10f
design -load postopt
yosys cd comparator
stat
select -assert-count 4 t:adder_carry
