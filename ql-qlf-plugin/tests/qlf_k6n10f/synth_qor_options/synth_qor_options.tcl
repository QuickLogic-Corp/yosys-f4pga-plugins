# QoR options of synth_ql: each one off (the default, unchanged result) and on.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
design -save rtl

proc synth {top args} {
    design -load rtl
    eval synth_ql -family qlf_k6n10f -top $top -dspv4 $args
    yosys cd $top
}

# -mcm: the constant multiply leaves the DSP. Yosys before 0.70 has no mcm
# pass; there the option is ignored and the DSP stays.
synth mul_c
select -assert-count 1 t:QL_DSP4_MULT
synth mul_c -mcm
if {[llength [info commands mcm]]} {
    select -assert-none t:QL_DSP4_MULT
} else {
    select -assert-count 1 t:QL_DSP4_MULT
}

# -carry_min_width: only $alu narrower than N bits leave adder_carry.
synth add9
select -assert-count 9 t:adder_carry
synth add9 -carry_min_width 9
select -assert-count 9 t:adder_carry
synth add9 -carry_min_width 10
select -assert-none t:adder_carry

# -cmp2lut_width: the 6-bit compare with a constant becomes one LUT.
synth cmp6
select -assert-min 1 t:adder_carry
synth cmp6 -cmp2lut_width 6
select -assert-none t:adder_carry
select -assert-count 1 t:\$lut

# -keep_syn_preserve: the two syn_preserve copies stay apart.
synth dup_ff
select -assert-count 2 t:sdffre
synth dup_ff -keep_syn_preserve
select -assert-count 4 t:sdffre

# Bad values are rejected.
design -load rtl
foreach bad {
    {synth_ql -family qlf_k6n10f -top add9 -carry_min_width x}
    {synth_ql -family qlf_k6n10f -top add9 -carry_min_width 0}
    {synth_ql -family qlf_k6n10f -top cmp6 -cmp2lut_width 9}
} {
    if {![catch {eval $bad} msg]} {
        error "accepted a command line that must be rejected: $bad"
    }
}
