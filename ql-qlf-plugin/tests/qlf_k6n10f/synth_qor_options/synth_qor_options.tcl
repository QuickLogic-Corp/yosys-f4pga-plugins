# QoR options of synth_ql: each one at its default and with the default changed.

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

# -small_mul_width (default 2): a multiply with an operand of at most N bits is
# built from logic; wider ones stay on the DSP. 0 turns it off.
synth mul_sel
select -assert-none t:QL_DSP4_MULT
synth mul_sel -small_mul_width 0
select -assert-count 1 t:QL_DSP4_MULT
synth mul_c
select -assert-count 1 t:QL_DSP4_MULT
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

# syn_preserve copies stay apart by default; -no_keep_syn_preserve lets them merge.
synth dup_ff
select -assert-count 4 t:*dff*
synth dup_ff -keep_syn_preserve
select -assert-count 4 t:*dff*
synth dup_ff -no_keep_syn_preserve
select -assert-count 2 t:*dff*

# The -cmp2lut_width cap is the family's LUT size: 4 is fine on qlf_k4n8, 5 is not.
design -load rtl
synth_ql -family qlf_k4n8 -top cmp6 -cmp2lut_width 4

# Bad values are rejected.
design -load rtl
foreach bad {
    {synth_ql -family qlf_k6n10f -top add9 -carry_min_width x}
    {synth_ql -family qlf_k6n10f -top add9 -carry_min_width 0}
    {synth_ql -family qlf_k6n10f -top cmp6 -cmp2lut_width 7}
    {synth_ql -family qlf_k4n8 -top cmp6 -cmp2lut_width 5}
    {synth_ql -family qlf_k6n10f -top mul_c -small_mul_width 9}
} {
    if {![catch {eval $bad} msg]} {
        error "accepted a command line that must be rejected: $bad"
    }
}
