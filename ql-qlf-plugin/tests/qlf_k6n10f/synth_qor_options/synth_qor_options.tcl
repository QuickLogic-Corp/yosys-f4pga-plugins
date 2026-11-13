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

# -small_mul_width: a multiply with an operand of at most N bits is built from
# logic; wider ones stay on the DSP.
synth mul_sel
select -assert-count 1 t:QL_DSP4_MULT
synth mul_sel -small_mul_width 2
select -assert-none t:QL_DSP4_MULT
synth mul_c -small_mul_width 4
select -assert-count 1 t:QL_DSP4_MULT

# -carry_min_width: only $alu narrower than N bits leave adder_carry.
synth add9
select -assert-count 9 t:adder_carry
synth add9 -carry_min_width 9
select -assert-count 9 t:adder_carry
synth add9 -carry_min_width 10
select -assert-none t:adder_carry

# -cmp2lut_width: the default (4) leaves the 6-bit compare with a constant to
# carry logic; width 6 makes it one LUT.
synth cmp6
select -assert-min 1 t:adder_carry
synth cmp6 -cmp2lut_width 6
select -assert-none t:adder_carry
select -assert-count 1 t:\$lut

# -keep_syn_preserve: the two syn_preserve copies stay apart.
synth dup_ff
select -assert-count 2 t:*dff*
synth dup_ff -keep_syn_preserve
select -assert-count 4 t:*dff*

# Bad values are rejected.
design -load rtl
foreach bad {
    {synth_ql -family qlf_k6n10f -top add9 -carry_min_width x}
    {synth_ql -family qlf_k6n10f -top add9 -carry_min_width 0}
    {synth_ql -family qlf_k6n10f -top cmp6 -cmp2lut_width 9}
    {synth_ql -family qlf_k6n10f -top mul_c -small_mul_width 0}
} {
    if {![catch {eval $bad} msg]} {
        error "accepted a command line that must be rejected: $bad"
    }
}
