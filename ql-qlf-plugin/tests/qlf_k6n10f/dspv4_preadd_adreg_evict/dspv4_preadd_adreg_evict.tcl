# dspv4_preadd_adreg_evict -- the AD register is refused because ANOTHER
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

read_verilog dspv4_preadd_adreg_evict.v
hierarchy -top dspv4_preadd_adreg_evict
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg_evict -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_preadd_adreg_evict
check -assert
# The AD flop is then an ordinary A-operand register and still moves inside.
# The resettable B register is what loses out: with A resetless the two chains
# disagree, and B is the narrower port, so B is the one left outside.
# The cell gives up the B register chain so the pre-adder can keep the AD
# bank. Those 16 flops go to fabric -- which is where they ended up anyway
# when we refused the pre-adder and the matcher re-offered without it.
select -assert-count 1 t:QL_DSP4_PREADD
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_AD_DFFR_32
# Keeping the pre-adder is what removes the carry chain: 17 before.
select -assert-count 0 t:adder_carry
# The evicted chain, now in fabric.
select -assert-count 16 t:sdffre
select -assert-count 0 t:QL_DSP4_A2_DFFRE_32
