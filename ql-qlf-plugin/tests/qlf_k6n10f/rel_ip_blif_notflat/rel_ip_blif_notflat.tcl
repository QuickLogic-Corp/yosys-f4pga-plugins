# Negative test: a hierarchical IP netlist (two .models with contents) is refused.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
synth_quicklogic -family qlf_k6n10f -top top -rel_ip_blif rel_ip_hier.eblif -blif [test_output_path "rel_ip_blif_notflat.eblif"]
