# dspv4_synplify_live_cin_keeps_m -- a live carry-in must keep the real M
# banks: three M banks and no ACC bank. See the .v and the twin,
# dspv4_synplify_gnd_cin_folds.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_synplify_live_cin_keeps_m.v
hierarchy -top dspv4_synplify_live_cin_keeps_m
$PASS_NAME -family qlf_k6n10f -top dspv4_synplify_live_cin_keeps_m -synplify -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_synplify_live_cin_keeps_m
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 1 t:QL_DSP4_M_DFFR_50
select -assert-count 1 t:QL_DSP4_MV_DFFR_43
select -assert-count 1 t:QL_DSP4_MK_DFFR
