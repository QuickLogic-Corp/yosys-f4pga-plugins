# Negative test: ql_dspv2_to_dspv4 must hard-error on this design (harness _negative=1).
yosys -import
if { [info procs ql_dspv2_to_dspv4] == {} } { plugin -i ql-qlf }
yosys -import
set LIB "../../../qlf_k6n10f"
read_verilog -lib -specify -nomem2reg $LIB/QL_DSPV2.v
read_verilog -lib -specify -nomem2reg $LIB/dspv4_sim.v $LIB/QL_DSP4.v
read_verilog dspv4_lonely.v
hierarchy -top lonely
ql_dspv2_to_dspv4
