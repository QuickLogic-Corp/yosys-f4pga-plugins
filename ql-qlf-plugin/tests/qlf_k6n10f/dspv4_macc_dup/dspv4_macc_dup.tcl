# dspv4_macc_dup -- two duplicate accumulator loops become one DSP.
#
# The only test here that merges SEQUENTIAL logic, so cell counts are not
# enough on their own: one bank and no fabric adder is equally what a pass that
# deleted a loop and stranded its reader would produce. Hence `check -assert`
# and a connectivity walk from each output back to the bank -- p1 and p2 must
# BOTH still be fed by it.
#
# NF-4: the pass is synth_quicklogic upstream and synth_ql in an aurora2 build,
# so the name is discovered rather than hardcoded.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_macc_dup.v
hierarchy -top dspv4_macc_dup
$PASS_NAME -family qlf_k6n10f -top dspv4_macc_dup -dspv4 -no_abc9 -lib_path $LIB/

yosys cd dspv4_macc_dup
# Nothing was left stranded by the merge.
check -assert
# One multiply, and the two loops collapsed into ONE accumulator bank.
select -assert-count 1 t:QL_DSP4_MULT
select -assert-count 1 t:QL_DSP4_ALU_ADD
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64
# Neither accumulate adder stayed in fabric. This is the assertion that fails
# without the merge: the product has two accumulator readers, the fan-out guards
# refuse both shapes, and the multiply falls back to a bare MULT with 72
# adder_carry and 108 sdffre beside it.
select -assert-count 0 t:adder_carry
select -assert-count 0 t:\$mul
select -assert-count 0 t:\$add
select -assert-count 0 t:\$sub
# 36 of the 108 flops remain: the register on p2. Nothing follows P in the DSP,
# so no flow absorbs it -- see dspv4_mult_regout2. The other 72 are the two
# merged accumulators, now the one bank.
select -assert-count 36 t:sdffre
# Both outputs are still driven by that bank. A merge that took one loop and
# deleted it would leave one of these walks empty.
select -assert-any o:p1 %ci* t:QL_DSP4_ACC_DFFRE_64 %i
select -assert-any o:p2 %ci* t:QL_DSP4_ACC_DFFRE_64 %i
