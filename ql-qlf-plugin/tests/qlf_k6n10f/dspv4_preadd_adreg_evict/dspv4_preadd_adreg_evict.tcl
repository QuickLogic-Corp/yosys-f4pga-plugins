# dspv4_preadd_adreg_evict -- the AD register and another register in the cell
# cannot share it, so that register is given up and the pre-adder kept.
#
# RSTN is shared by the AD and operand banks. Absorbing both registers would
# reset one of them on a signal, or a level, its RTL never asked for. Without
# the check the design synthesises, packs and routes, and only the values
# after a reset pulse are wrong.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_adreg_evict.v
hierarchy -top dspv4_preadd_adreg_evict
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg_evict -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_adreg_evict
check -assert
# Every block keeps its pre-adder and its AD register.
select -assert-count 6 t:QL_DSP4_PREADD
select -assert-count 6 t:QL_DSP4_MULT
select -assert-count 6 t:QL_DSP4_AD_DFFR_32
# Keeping the pre-adder is what removes the carry chain: 17 per block before.
select -assert-count 0 t:adder_carry
# The five evicted B chains (16 each), and cr's and cn's result registers
# (33 each), now in fabric. None reached a B or P bank.
select -assert-count 146 t:sdffre
select -assert-count 0 t:QL_DSP4_B1_DFFRE_18
select -assert-count 0 t:QL_DSP4_B2_DFFRE_18
select -assert-count 0 t:QL_DSP4_A2_DFFRE_32
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
# rb's AD register is resetless, so its cell's RSTN stays tied off; the
# other five reset their AD bank on rstn.
select -assert-count 5 w:rstn %co:+\[R\] t:QL_DSP4_AD_DFFR_32 %i
# cr's and cn's AD banks run on clk2, their own clock.
select -assert-count 2 w:clk2 %co:+\[clk\] t:QL_DSP4_AD_DFFR_32 %i
