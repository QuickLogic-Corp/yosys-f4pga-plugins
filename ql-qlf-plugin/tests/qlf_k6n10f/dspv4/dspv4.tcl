# Positive unit tests for the ql_dspv2_to_dspv4 pass (DSP-V2 -> DSP-V4, Phase 1).
#
# Per-cell MULT/MULTACC conversion and CONCAT_CASCADE+MULTADD fusion produce
# monolithic QL_DSP4 base cells (Appendix-A config words are logged by the pass).
# Cell-type assertions fail the run (nonzero exit) if conversion is wrong.
# Hard-error behaviour is covered by the sibling negative tests
# (dspv4_frac / dspv4_lonely / dspv4_k2).

yosys -import
if { [info procs ql_dspv2_to_dspv4] == {} } { plugin -i ql-qlf }
yosys -import

set LIB "../../../qlf_k6n10f"
read_verilog -lib -specify -nomem2reg $LIB/QL_DSPV2.v
read_verilog -lib -specify -nomem2reg $LIB/dspv4_sim.v $LIB/QL_DSP4.v
design -save PRIMS

proc convert_top {top} {
    design -load PRIMS
    read_verilog dspv4.v
    hierarchy -top $top
    ql_dspv2_to_dspv4
    yosys cd $top
    yosys select -assert-count 1 t:QL_DSP4
    yosys select -assert-count 0 t:QL_DSPV2
}

convert_top mult         ;# A*B        -> OPMODE 000000101
convert_top multacc      ;# acc+A*B    -> OPMODE 000100101, PREG=1, CEP=load_acc(1)
convert_top multacc_hold ;# load_acc=0 -> CEP tied 0 (hold), still one QL_DSP4
convert_top fuse         ;# A*B + A1:B1 -> OPMODE 000110101, C={A1,B1}

# MULTACC + output register: 1 QL_DSP4 (PREG=accumulator) plus an external dffre
# bank materialising the extra output-register stage.
design -load PRIMS
read_verilog dspv4.v
hierarchy -top multacc_oreg
ql_dspv2_to_dspv4
yosys cd multacc_oreg
yosys select -assert-count 1 t:QL_DSP4
yosys select -assert-count 0 t:QL_DSPV2
yosys select -assert-min 1 t:dffre

puts "=== ql_dspv2_to_dspv4 positive tests PASSED ==="
