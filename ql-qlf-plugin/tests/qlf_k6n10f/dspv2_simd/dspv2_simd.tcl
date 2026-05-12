yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

# Test DSPv2 SIMD packing (ql_dsp_simd -dspv2 pass)
# Two independent 16x9 multiplies should be packed into a single QL_DSPV2

proc test_dspv2_simd {top expected_dsp_count description} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count ${expected_dsp_count} t:QL_DSPV2
    return
}

read_verilog dspv2_simd.v
design -save read

# Two 8x8 multiplies packed into 1 QL_DSPV2 (SIMD / fractured mode)
test_dspv2_simd "simd_mult_8x8" 1 "two 8x8 SIMD packing"

# Two 16x9 multiplies packed into 1 QL_DSPV2 (SIMD / fractured mode)
test_dspv2_simd "simd_mult_16x9" 1 "two 16x9 SIMD packing"

# Three 8x8 multiplies: 2 packed SIMD + 1 standalone = 2 QL_DSPV2
test_dspv2_simd "simd_mult_three" 2 "three 8x8 needs 2 DSPs"
