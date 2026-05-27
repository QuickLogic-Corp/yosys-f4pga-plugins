# Test DSPv2 MACC inference.
#
# Only 16x9-width signed MACs without a $mux clear and without unsigned
# operands are inferred as QL_DSPV2_MULTACC by ql_dsp_macc -dspv2.
# Designs that fail any of those gates fall through to mul2dsp and produce
# a plain QL_DSPV2_MULT with the accumulator FF left in fabric.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

proc test_dspv2_macc {top expected_subtype rejected_subtype} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count 1 t:${expected_subtype}
    select -assert-count 0 t:${rejected_subtype}
    select -assert-count 0 t:QL_DSPV2
    # Acceptance criterion 7: no DSPv1 cells must remain on the -dspv2 path.
    select -assert-count 0 t:QL_DSP2 t:QL_DSP3
    select -assert-count 0 t:dsp_t1_10x9x32 t:dsp_t1_20x18x64
    return
}

read_verilog dspv2_macc.v
design -save read

# --- Accepted MACC variants -> QL_DSPV2_MULTACC ---

# 16x9 MAC, signed, sync reset, no enable (baseline).
test_dspv2_macc "macc_16x9"      "QL_DSPV2_MULTACC" "QL_DSPV2_MULT"

# 16x9 MAC, subtract (R-MACC-2d, SUBTRACT=1).
test_dspv2_macc "macc_16x9_sub"  "QL_DSPV2_MULTACC" "QL_DSPV2_MULT"

# 16x9 MAC, enable (R-MACC-2d, load_acc_i = EN).
test_dspv2_macc "macc_16x9_en"   "QL_DSPV2_MULTACC" "QL_DSPV2_MULT"

# 16x9 MAC, async reset (R-MACC-2d, reset_i from $adff).
test_dspv2_macc "macc_16x9_arst" "QL_DSPV2_MULTACC" "QL_DSPV2_MULT"

# --- Rejected MACC variants -> fall through to QL_DSPV2_MULT ---

# 32x18 MAC: ql_dsp_macc -dspv2 rejects ops wider than 16x9 (R-MACC-2c);
# 2026.2 release scope leaves the accumulator FF in fabric.
test_dspv2_macc "macc_32x18"          "QL_DSPV2_MULT" "QL_DSPV2_MULTACC"

# Unsigned MAC: DSPv2 is signed-only (R-MACC-2a). Rejection -> MULT only.
test_dspv2_macc "macc_16x9_unsigned"  "QL_DSPV2_MULT" "QL_DSPV2_MULTACC"

# Accumulator-clear via $mux is rejected (R-MACC-2b) -> MULT only.
test_dspv2_macc "macc_16x9_clearmux"  "QL_DSPV2_MULT" "QL_DSPV2_MULTACC"
