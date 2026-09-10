# Negative test: an IP that instantiates a primitive the cell library does
# not define is refused with a hint, instead of failing inside VPR.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
synth_quicklogic -family qlf_k6n10f -top top -rel_ip_blif rel_ip_noprim.eblif -blif [test_output_path "rel_ip_blif_noprim.eblif"]
