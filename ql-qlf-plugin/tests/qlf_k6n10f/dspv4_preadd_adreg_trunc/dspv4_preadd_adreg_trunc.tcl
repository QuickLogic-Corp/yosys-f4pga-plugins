# dspv4_preadd_adreg_trunc -- the multiply reads less of the registered sum
# than the pre-adder produces, so the fold has to be refused.
#
# Run with -no_opt on purpose. In the default flow wreduce narrows the adder
# before this pass sees it and a different guard refuses the shape, which hides
# whether this one works. -no_opt is a user-visible Aurora setting, so the
# unnarrowed shape reaches the pass in real projects.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_preadd_adreg_trunc.v
hierarchy -top dspv4_preadd_adreg_trunc
$PASS_NAME -family qlf_k6n10f -top dspv4_preadd_adreg_trunc -dspv4 -no_abc9 -no_opt -lib_path $LIB/

yosys cd dspv4_preadd_adreg_trunc
# No `check -assert` here. Under -no_opt there is no opt_clean to tie off the
# ALU's unused CIN, so every DSP leaves one undriven wire -- a design with no
# pre-adder at all reports the same thing. The cell counts below are what
# carry this test.
# The multiply still belongs in a DSP; only the pre-adder is refused.
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 0 t:QL_DSP4_PREADD
select -assert-count 0 t:QL_DSP4_PRESUB
# The adder stays in fabric, which is what refusing costs.
select -assert-min 1 t:adder_carry
