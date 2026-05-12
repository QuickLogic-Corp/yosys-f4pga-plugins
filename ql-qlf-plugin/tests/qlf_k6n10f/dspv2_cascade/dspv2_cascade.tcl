yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf}
yosys -import  ;# ingest plugin commands

# Test DSPv2 Z-cascade (ql_dsp_dspv2 cascade pattern)
# Verifies that post-adder is absorbed and z_cout/z_cin cascade is inferred

# Full synthesis with dspv2 and check DSP count
proc test_dspv2_cascade {top expected_dsp_count check_no_adder} {
    design -load read
    hierarchy -top ${top}
    synth_quicklogic -family qlf_k6n10f -top ${top} -dspv2
    yosys cd ${top}
    select -assert-count ${expected_dsp_count} t:QL_DSPV2
    if {${check_no_adder}} {
        # Post-adder should be absorbed - no standalone $add/$sub cells
        select -assert-count 0 t:$add t:$sub %u
    }
    return
}

read_verilog dspv2_cascade.v
design -save read

# Cascade add: 2 DSPs connected via cascade (post-adder absorbed)
test_dspv2_cascade "cascade_add" 2 1

# Cascade sub: 2 DSPs connected via cascade (post-sub absorbed)
test_dspv2_cascade "cascade_sub" 2 1

# Independent multiplies: 2 DSPs, no cascade (no adder to absorb)
test_dspv2_cascade "no_cascade_independent" 2 0
