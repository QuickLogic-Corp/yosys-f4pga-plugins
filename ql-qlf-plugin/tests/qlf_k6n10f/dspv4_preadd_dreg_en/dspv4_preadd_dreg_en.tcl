# dspv4_preadd_dreg_en -- clock enables on the D bank, and enable eviction.
#
# The `w:en0 %co:+[E]` assertion is the one that matters: a D bank with its E
# tied to 1 still counts as a D_DFFRE_27, so a plain cell count cannot tell an
# absorbed enable from a dropped one. Checked against a version with the enable
# removed, where this assertion fails and every other one still passes.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_dreg_en.v
hierarchy -top dspv4_preadd_dreg_en
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_dreg_en -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_dreg_en
check -assert
select -assert-count 2 t:QL_DSP4_PREADD
select -assert-count 2 t:QL_DSP4_MULT
# Both cells keep their D register.
select -assert-count 2 t:QL_DSP4_D_DFFRE_27
# The enable travelled into the bank rather than being tied off.
select -assert-count 1 w:en0 %co:+\[E\] t:QL_DSP4_D_DFFRE_27 %i
# The four-enable cell: A and P stay, B is evicted as the narrowest port.
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 16 t:sdffre
select -assert-count 0 t:adder_carry
