# dspv4_mult_wide_result -- a result wider than the 50-bit P port must not be
# absorbed, and must not lose its top bits.
#
# `check -assert` in the prologue is what catches the original defect: the top
# 14 bits of `p` had no driver. The counts then pin down the intended outcome --
# multiply in a DSP, accumulator in fabric.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_mult_wide_result.v
hierarchy -top dspv4_mult_wide_result
$PASS_NAME -family qlf_k6n10f -top dspv4_mult_wide_result -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_mult_wide_result
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:\$mul
# The accumulator did NOT move into the DSP: it is 64 bits and P is 50.
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-min 1 t:sdffre
