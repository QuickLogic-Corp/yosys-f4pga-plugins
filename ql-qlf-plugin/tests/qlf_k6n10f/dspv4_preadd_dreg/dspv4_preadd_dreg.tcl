# dspv4_preadd_dreg -- the D-depth sweep: D 0/1/2 against AD 0/1.
#
# Six blocks, so the bank counts say which depths were taken:
#
#   D depth   0   1   2   0   1   2
#   AD depth  0   0   0   1   1   1
#   D bank    -   x   x   -   x   x    -> 4 QL_DSP4_D_DFFRE_27
#   AD bank   -   -   -   x   x   x    -> 3 QL_DSP4_AD_DFFR_32
#
# The two D-depth-2 blocks keep their OUTER stage in fabric, one 16-bit stage
# each. That surplus is the point of the depth sweep: absorbing it as well
# would move D a cycle earlier than the RTL asked for, and dropping it would
# lose a cycle -- both are wrong, and both show the same bank count.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_dreg.v
hierarchy -top dspv4_preadd_dreg
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_dreg -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_dreg
check -assert
# Every block folded its pre-adder.
select -assert-count 6 t:QL_DSP4_PREADD
select -assert-count 6 t:QL_DSP4_MULT
select -assert-count 0 t:adder_carry
# Four blocks register D, three register the pre-adder's output.
select -assert-count 4 t:QL_DSP4_D_DFFRE_27
select -assert-count 3 t:QL_DSP4_AD_DFFR_32
# Exactly the two surplus D stages are left outside: 2 x 16 bits. The library
# maps a plain $dff onto sdffre with its reset tied off, so that is the cell to
# count -- t:dffre is zero here whether or not the flops survived.
select -assert-count 32 t:sdffre
select -assert-count 0 t:dffre
