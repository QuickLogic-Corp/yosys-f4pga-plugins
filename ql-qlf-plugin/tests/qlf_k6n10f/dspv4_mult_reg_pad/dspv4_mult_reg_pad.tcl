yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_reg_pad.v
hierarchy -top dspv4_mult_reg_pad
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_reg_pad -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_reg_pad
check -assert
select -assert-count 1 t:QL_DSP4_MULT
# The first register reaches P; the data-padded second one must stay out.
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-min 1 t:sdffre
