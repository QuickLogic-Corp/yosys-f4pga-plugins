# Positive test: DSP-to-DSP product cascade (z_cout -> z_cin) must survive as two
# connected QL_DSP4 cells. The pass wires stage1.z_cout -> PCOUT and
# stage2.z_cin -> PCIN onto the same net; if that cascade wiring were missing,
# stage1's output would be dead and opt_clean would prune it (count -> 1).
yosys -import
if { [info procs ql_dspv2_to_dspv4] == {} } { plugin -i ql-qlf }
yosys -import

set LIB "../../../qlf_k6n10f"
read_verilog -lib -specify -nomem2reg $LIB/QL_DSPV2.v
read_verilog -lib -specify -nomem2reg $LIB/dspv4_sim.v $LIB/QL_DSP4.v
read_verilog dspv4_cascade.v
hierarchy -top cascade
ql_dspv2_to_dspv4
opt_clean
yosys cd cascade
yosys select -assert-count 2 t:QL_DSP4   ;# both stages survive => cascade is connected
yosys select -assert-count 0 t:QL_DSPV2
# Guard against the deferred-removal (use-after-free) regression: the pass must not
# reprocess its own output (which produced doubly-suffixed *_DSP4_DSP4 cells).
yosys select -assert-count 0 c:*_DSP4_DSP4

puts "=== ql_dspv2_to_dspv4 cascade (z_cout->PCOUT) test PASSED ==="
