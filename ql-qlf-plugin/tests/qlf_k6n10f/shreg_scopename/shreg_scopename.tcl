# Each flop keeps the scope of the instance it came from (scopename), also when
# synth_ql maps the chains to shift-register cells (sh_dffre).
#
# Fails today: shregmap joins u0's and u1's chains into one $__SHREG_ cell carrying
# scopename u0 only, and the sh_dffre cells it maps to carry no scopename at all.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
hierarchy -top top
yosys proc
flatten -scopename
synth_ql -family qlf_k6n10f -top top
stat

select -assert-count 20 t:sh_dffre
select -assert-count 10 t:sh_dffre a:scopename=u0 %i
select -assert-count 10 t:sh_dffre a:scopename=u1 %i
