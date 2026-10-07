# dspv4_preadd_adreg_cellrst -- the AD register is refused because ANOTHER
# absorbed register drives the cell-wide RSTN.
#
# The $dff restriction in the pattern only covers a flop carrying its own
# reset. RSTN is shared with the operand banks, so an operand register with a
# reset would reset the AD bank as well -- and this RTL never asks for that.
# Without the check the design synthesises, packs and routes, and only the
# values after a reset pulse are wrong.
#
# The log line names the refusal, so a future change that removes the check
# fails here loudly.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_adreg_cellrst.v
hierarchy -top dspv4_preadd_adreg_cellrst
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg_cellrst -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_adreg_cellrst
check -assert
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:QL_DSP4_AD_DFFR_32
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-min 1 t:adder_carry
# The AD flop is then an ordinary A-operand register and still moves inside.
# The resettable B register is what loses out: with A resetless the two chains
# disagree, and B is the narrower port, so B is the one left outside.
select -assert-count 1 t:QL_DSP4_A2_DFFRE_32
select -assert-count 16 t:sdffre
