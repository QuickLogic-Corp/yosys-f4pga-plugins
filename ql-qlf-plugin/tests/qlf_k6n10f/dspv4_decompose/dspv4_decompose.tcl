# Positive unit tests for the DSP-V4 Phase-2 decompose techmap.
#
# ql_dspv2_to_dspv4 produces one monolithic QL_DSP4 per DSP; the
# `techmap -map dsp4_logical_map.v` step then rewrites it into the dsp4_logical
# operating-mode leaf cells (QL_DSP4_MULT / _ALU_ADD / _PREADD / _ACC_DFFRE /
# ...). The assertions below fail the run (nonzero exit) if the decomposition is
# wrong: no QL_DSP4 / QL_DSPV2 may remain, and the expected leaves must appear.

yosys -import
if { [info procs ql_dspv2_to_dspv4] == {} } { plugin -i ql-qlf }
yosys -import

set LIB "../../../qlf_k6n10f"
read_verilog -lib -specify -nomem2reg $LIB/QL_DSPV2.v
read_verilog -lib -specify -nomem2reg $LIB/dspv4_sim.v $LIB/QL_DSP4.v
read_verilog -lib -specify -nomem2reg $LIB/QL_DSP4_leaves.v
design -save PRIMS

# Convert V2 -> monolithic QL_DSP4, then decompose into dsp4_logical leaves.
proc decompose_top {top} {
    design -load PRIMS
    read_verilog dspv4_decompose.v
    hierarchy -top $top
    ql_dspv2_to_dspv4
    techmap -map ../../../qlf_k6n10f/dsp4_logical_map.v
    clean
    yosys cd $top
    # Fully decomposed: nothing monolithic left.
    yosys select -assert-count 0 t:QL_DSP4
    yosys select -assert-count 0 t:QL_DSPV2
    # Every Phase-1 mode multiplies and (here) uses the add ALU variant.
    yosys select -assert-count 1 t:QL_DSP4_MULT
    yosys select -assert-count 1 t:QL_DSP4_ALU_ADD
    yosys cd
}

decompose_top mult          ;# A*B
decompose_top multacc       ;# acc + A*B  -> 64-bit accumulator register
yosys cd multacc
yosys select -assert-count 64 t:QL_DSP4_ACC_DFFRE
yosys cd

decompose_top preadd_mult   ;# (D+B)*A    -> pre-adder (add)
yosys cd preadd_mult
yosys select -assert-count 1 t:QL_DSP4_PREADD
yosys select -assert-count 0 t:QL_DSP4_PRESUB
yosys cd

decompose_top fuse          ;# A*B + C (fused)

puts "=== dspv4 decompose techmap positive tests PASSED ==="
