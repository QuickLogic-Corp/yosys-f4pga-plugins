# dspv4_preadd_width_edge -- the width bound is inclusive. REQ-D2.
#
# w_sum = 18 here, exactly DSPV4_AD_B_WIDTH. Mutation-checked: turning the
# `<=` into `<` fails this test and _width_const, while _width_ok and
# _width_over both still pass -- so without these two the off-by-one ships.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_width_edge.v
hierarchy -top dspv4_preadd_width_edge
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_width_edge -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_width_edge
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
