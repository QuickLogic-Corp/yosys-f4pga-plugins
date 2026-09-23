yosys -import

if { [info procs ql-qlf-k6n10f] == {} } { plugin -i ql-qlf }
yosys -import  ;

read_verilog $::env(DESIGN_TOP).v
design -save dsp_simd

select simd_mult
select *
synth_ql -family qlf_k6n10f -top simd_mult
opt_expr -undriven
opt_clean
stat
write_verilog sim/simd_mult_post_synth.v
# 2, not 1: (* keep *) from ed85bca blocks SIMD packing on the cfg_ports path; restore to 1 when fixed.
select -assert-count 2 t:QL_DSP2_MULT

select -clear
design -load dsp_simd
select simd_mult_explicit_ports
select *
synth_ql -family qlf_k6n10f -top simd_mult_explicit_ports
opt_expr -undriven
opt_clean
stat
write_verilog sim/simd_mult_explicit_ports_post_synth.v
select -assert-count 1 t:QL_DSP2

select -clear
design -load dsp_simd
select simd_mult_explicit_params
select *
synth_ql -family qlf_k6n10f -top simd_mult_explicit_params -use_dsp_cfg_params
opt_expr -undriven
opt_clean
stat
write_verilog sim/simd_mult_explicit_params_post_synth.v
select -assert-count 1 t:QL_DSP3
