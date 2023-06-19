yosys -import

if { [info procs ql-qlf-k6n10f] == {} } { plugin -i ql-qlf }
yosys -import  ;

read_verilog $::env(DESIGN_TOP).v
design -save asymmetric_bram18k_sdp

select spram_9x2048_18x1024
select *
synth_quicklogic -family qlf_k6n10f -top spram_9x2048_18x1024 -bram_types
opt_expr -undriven
opt_clean
stat
write_verilog sim/spram_9x2048_18x1024_post_synth.v  
select -assert-count 1 t:TDP36K_BRAM_A_X9_B_X18_nonsplit 

select -clear
design -load asymmetric_bram18k_sdp
select spram_18x1024_9x2048
select *
synth_quicklogic -family qlf_k6n10f -top spram_18x1024_9x2048 -bram_types
opt_expr -undriven
opt_clean
stat
write_verilog sim/spram_18x1024_9x2048_post_synth.v
select -assert-count 1 t:TDP36K_BRAM_A_X18_B_X9_nonsplit 