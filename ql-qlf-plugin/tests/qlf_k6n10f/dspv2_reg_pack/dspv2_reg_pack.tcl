yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

# Test DSPv2 register packing (ql_dsp_dspv2 pass)
# Verifies that flip-flops on A/B inputs and Z output are absorbed into the DSP

proc test_dspv2_reg_pack {top expected_dff_count description} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    # Should always produce exactly 1 QL_DSPV2
    select -assert-count 1 t:QL_DSPV2
    # Check remaining DFFs - packed regs should NOT leave behind separate flops
    select -assert-count ${expected_dff_count} t:$dff t:$dffe t:$adff t:$adffe %u
    return
}

read_verilog dspv2_reg_pack.v
design -save read

# Output register should be packed into DSP (0 remaining DFFs)
test_dspv2_reg_pack "mult_output_reg" 0 "output register packing"

# Input A register should be packed into DSP (0 remaining DFFs)
test_dspv2_reg_pack "mult_input_a_reg" 0 "input A register packing"

# Input B register should be packed into DSP (0 remaining DFFs)
test_dspv2_reg_pack "mult_input_b_reg" 0 "input B register packing"

# All registers packed - A, B inputs and Z output (0 remaining DFFs)
test_dspv2_reg_pack "mult_all_regs" 0 "all registers packing"

# 16x9 fractured with output register (0 remaining DFFs)
test_dspv2_reg_pack "mult_16x9_output_reg" 0 "16x9 output register packing"
