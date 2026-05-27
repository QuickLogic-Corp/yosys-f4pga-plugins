# R-SCRIPT-4 / R-TYPES-2: ql_dspv2_types runs unconditionally at the end of
# synth_quicklogic, but it must be a strict no-op on DSPv1 netlists -- it must
# not rewrite QL_DSP2 / QL_DSP3 / dsp_t1_* cells into any QL_DSPV2_* subtype.
#
# This test runs the default (DSPv1) flow on a plain 20x18 multiply and
# asserts:
#   - exactly one QL_DSP2_MULT (or QL_DSP3_MULT with -use_dsp_cfg_params),
#   - zero cells of any QL_DSPV2* subtype.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

proc test_v1_noop {use_cfg_params expected_v1_cell} {
    design -load read
    hierarchy -top mult_20x18_s
    if {${use_cfg_params} == 1} {
        synth_quicklogic -family qlf_k6n10f -top mult_20x18_s -use_dsp_cfg_params
    } else {
        synth_quicklogic -family qlf_k6n10f -top mult_20x18_s
    }
    yosys cd mult_20x18_s
    select -assert-count 1 t:${expected_v1_cell}
    # The DSPv2-types pass must not have produced any DSPv2 subtype cells.
    select -assert-count 0 t:QL_DSPV2
    select -assert-count 0 t:QL_DSPV2_MULT t:QL_DSPV2_MULTACC
    select -assert-count 0 t:QL_DSPV2_MULT_REGIN t:QL_DSPV2_MULT_REGOUT t:QL_DSPV2_MULT_REGIN_REGOUT
    select -assert-count 0 t:QL_DSPV2_MULTACC_REGIN t:QL_DSPV2_MULTACC_REGOUT t:QL_DSPV2_MULTACC_REGIN_REGOUT
    select -assert-count 0 t:QL_DSPV2_MULTADD t:QL_DSPV2_MULTACC_NEG t:QL_DSPV2_PREADDER_MULT
    return
}

read_verilog dspv2_types_v1_noop.v
design -save read

# Cfg-ports DSPv1 path.
test_v1_noop 0 "QL_DSP2_MULT"

# Cfg-params DSPv1 path.
test_v1_noop 1 "QL_DSP3_MULT"
