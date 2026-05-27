# Test DSPv2 SIMD packing (ql_dsp_simd -dspv2).
# Pairs of 16x9 multiplies are packed into a single fractured 32x18 cell;
# after ql_dspv2_types the cell type is QL_DSPV2_MULT (or QL_DSPV2_MULTACC
# when the half-cells originated from a MAC). Mismatched control ports or a
# (* keep *) attribute on a port wire must block packing.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

proc test_dspv2_simd {top expected_mult expected_multacc description} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count ${expected_mult}    t:QL_DSPV2_MULT
    select -assert-count ${expected_multacc} t:QL_DSPV2_MULTACC
    select -assert-count 0 t:QL_DSPV2
    # Acceptance criterion 7: no DSPv1 cells must remain on the -dspv2 path.
    select -assert-count 0 t:QL_DSP2 t:QL_DSP3
    select -assert-count 0 t:dsp_t1_10x9x32 t:dsp_t1_20x18x64
    return
}

read_verilog dspv2_simd.v
design -save read

# --- Positive SIMD-packing cases ---

# Two 8x8 multiplies packed into 1 fractured QL_DSPV2_MULT.
test_dspv2_simd "simd_mult_8x8"   1 0 "two 8x8 SIMD packing"

# Two 16x9 multiplies packed into 1 fractured QL_DSPV2_MULT.
test_dspv2_simd "simd_mult_16x9"  1 0 "two 16x9 SIMD packing"

# Three 8x8 multiplies: 2 packed SIMD + 1 standalone = 2 QL_DSPV2_MULT.
test_dspv2_simd "simd_mult_three" 2 0 "three 8x8 needs 2 DSPs"

# --- Negative SIMD-packing cases ---

# R-SIMD-1: different clocks -> control ports do not match -> NO packing.
# Each MAC remains its own 16x9 cell, so we expect 2 QL_DSPV2_MULTACC.
test_dspv2_simd "simd_mismatched_clk" 0 2 "different clocks block packing"

# R-SIMD-3c: (* keep *) on a port wire blocks packing of that pair ->
# 2 standalone 16x9 multiplies survive.
test_dspv2_simd "simd_mult_keep_attr" 2 0 "(* keep *) blocks packing"
