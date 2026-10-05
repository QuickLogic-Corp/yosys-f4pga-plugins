# dspv4_preadd_addc -- pre-adder feeding a fused adder (Phase 4 step 2).
#
# adder_carry 0 is the assertion with teeth, and it has to be zero for TWO
# additions here: the pre-add and the addend. Step 1 inferred the pre-adder but
# refused this shape, leaving the fused adder in fabric -- which no value check
# would notice, since the arithmetic is right either way.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_addc.v
hierarchy -top dspv4_preadd_addc
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_addc -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_addc
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
select -assert-count 1 t:QL_DSP4_MULT
# The addend was fused into the ALU rather than left as a carry chain.
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
