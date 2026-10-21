# dspv4_preadd_adreg_rst -- AD registers with a reset are ABSORBED.
#
# The AD bank resets from the cell-wide RSTN, like every operand bank, so a
# resettable pre-adder register belongs inside. The checks below pin both the
# cells and the reset wiring: an AD bank whose R is tied off still counts as
# one QL_DSP4_AD_DFFR_32, and only the R connection shows the reset survived.
#
# The log assertion in tests/Makefile is the other half: four PREADD words.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_adreg_rst.v
hierarchy -top dspv4_preadd_adreg_rst
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg_rst -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_adreg_rst
check -assert
# Four pre-adders, four AD banks, and no carry chain left in fabric.
select -assert-count 4 t:QL_DSP4_PREADD
select -assert-count 4 t:QL_DSP4_MULT
select -assert-count 4 t:QL_DSP4_AD_DFFR_32
select -assert-count 0 t:adder_carry
# ch's D and B registers share the AD register's reset, so they come inside.
select -assert-count 1 t:QL_DSP4_D_DFFRE_27
select -assert-count 1 t:QL_DSP4_B2_DFFRE_18
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
select -assert-count 0 t:sdffre
select -assert-count 0 t:dffre
# The reset reached the banks. lo, ch and pr reset on rstn directly.
select -assert-count 3 w:rstn %co:+\[R\] t:QL_DSP4_AD_DFFR_32 %i
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_D_DFFRE_27 %i
select -assert-count 1 w:rstn %co:+\[R\] t:QL_DSP4_B2_DFFRE_18 %i
# hi resets on rst, active high, so its AD bank reads rst through one
# inverter: never rst itself, which would reset on the wrong level.
select -assert-count 0 w:rst %co:+\[R\] t:QL_DSP4_AD_DFFR_32 %i
select -assert-count 1 w:rst %co:+\[A\] t:\$lut %i %co:+\[Y\] w:* %i %co:+\[R\] t:QL_DSP4_AD_DFFR_32 %i
# pr's P register keeps its own reset on ACCRSTN, apart from RSTN.
select -assert-count 1 w:rst2n %co:+\[R\] t:QL_DSP4_ACC_DFFRE_64 %i
