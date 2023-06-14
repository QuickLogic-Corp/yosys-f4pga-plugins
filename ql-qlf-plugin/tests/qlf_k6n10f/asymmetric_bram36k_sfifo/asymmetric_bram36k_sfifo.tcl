yosys -import

if { [info procs ql-qlf-k6n10f] == {} } { plugin -i ql-qlf }
yosys -import  ;

read_verilog $::env(DESIGN_TOP).v
design -save asymmetric_bram36k_sfifo

select f4096x9_1024x36
select *
synth_quicklogic -family qlf_k6n10f -top f4096x9_1024x36 -bram_types
opt_expr -undriven
opt_clean
stat
write_verilog sim/f4096x9_1024x36_post_synth.v
select -assert-count 1 t:TDP36K_FIFO_SYNC_A_X9_B_X36_nonsplit 

select -clear
design -load asymmetric_bram36k_sfifo
select f2048x18_1024x36
select *
synth_quicklogic -family qlf_k6n10f -top f2048x18_1024x36 -bram_types
opt_expr -undriven
opt_clean
stat
write_verilog sim/f2048x18_1024x36_post_synth.v  
select -assert-count 1 t:TDP36K_FIFO_SYNC_A_X18_B_X36_nonsplit 

select -clear
design -load asymmetric_bram36k_sfifo
select f2048x18_4098x9
select *
synth_quicklogic -family qlf_k6n10f -top f2048x18_4098x9 -bram_types
opt_expr -undriven
opt_clean
stat
write_verilog sim/f2048x18_4098x9_post_synth.v
select -assert-count 1 t:TDP36K_FIFO_SYNC_A_X18_B_X9_nonsplit 

select -clear
design -load asymmetric_bram36k_sfifo
select f1024x36_2048x18
select *
synth_quicklogic -family qlf_k6n10f -top f1024x36_2048x18 -bram_types
opt_expr -undriven
opt_clean
stat
write_verilog sim/f1024x36_2048x18_post_synth.v
select -assert-count 1 t:TDP36K_FIFO_SYNC_A_X36_B_X18_nonsplit 