# dspv4_preadd_dreg_asym -- D registered twice, A once.
#
# The assertion that matters is the fabric flop count. Of the three design
# registers two move inside -- D's inner stage into the D bank, A's into
# AREG1 -- and D's outer stage, 16 bits, stays outside. Absorbing all three
# would be the latency bug; dropping the surplus would be worse. Both show the
# same D bank count, so only the leftover 16 flops tell them apart.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_dreg_asym.v
hierarchy -top dspv4_preadd_dreg_asym
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_dreg_asym -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_dreg_asym
check -assert
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:adder_carry
# One stage each, on the two ports that have one.
select -assert-count 1 t:QL_DSP4_D_DFFRE_27
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
# A is one deep, so its stage-0 slot stays empty. Filling it would be the
# (1,0) encoding, which reads as delay 0 rather than delay 1.
select -assert-count 0 t:QL_DSP4_A1_DFFRE_32
# D's surplus stage is left outside, not dropped: 16 bits of it. The library
# maps a plain $dff onto sdffre with its reset tied off, so that is the cell to
# count -- t:dffre is zero here whether or not the flop survived.
select -assert-count 16 t:sdffre
select -assert-count 0 t:dffre
