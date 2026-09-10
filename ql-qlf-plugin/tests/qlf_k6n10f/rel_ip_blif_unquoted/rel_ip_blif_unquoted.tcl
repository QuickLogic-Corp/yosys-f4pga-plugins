# Negative test: an annotation value that is not a quoted string is refused.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
synth_quicklogic -family qlf_k6n10f -top top -rel_ip_blif rel_ip_unquoted.eblif -blif [test_output_path "rel_ip_blif_unquoted.eblif"]
