yosys -import
read_verilog -sv memhammer.v
design -save ast

set libdir ../../../../
scratchpad -set ql.lib_path $libdir
set tdp36k_simsource [list $libdir/qlf_k6n10f/brams_sim.v $libdir/qlf_k6n10f/TDP18K_FIFO.v $libdir/qlf_k6n10f/ufifo_ctl.v ../sram1024x18_mem.v]

foreach {depth_log2 width} [list 10 36 10 32 11 18 11 16 12 9 12 8 13 4 14 2 15 1] {
	design -load ast
	chparam -set DEPTH_LOG2 $depth_log2 -set WIDTH $width
	prep;
	opt_dff;
	prep -rdff;

	synth_quicklogic -family qlf_k6n10f -run map_bram

	select -assert-none {t:$mem_v2} {t:$mem}
	select -assert-count 1 t:TDP36K
	select -assert-count 1 t:TDP36K a:is_split=0 %i
	select -assert-count 1 t:TDP36K a:was_split_candidate=0 %i

	read_verilog {*}$tdp36k_simsource
	prep
	hierarchy -top top
	stat
	sim -assert -q -n [expr 2**$depth_log2+4] -clock clk
}

foreach {depth_log2 width} [list 10 18 10 16 11 9 11 8 12 4 13 2 14 1] {
	design -load ast
	chparam -set DEPTH_LOG2 $depth_log2 -set WIDTH $width
	prep;
	opt_dff;
	prep -rdff;

	synth_quicklogic -family qlf_k6n10f -run map_bram

	select -assert-none {t:$mem_v2} {t:$mem}
	select -assert-count 1 t:TDP36K
	select -assert-count 1 t:TDP36K a:is_split=0 %i
	select -assert-count 1 t:TDP36K a:was_split_candidate=1 %i

	read_verilog {*}$tdp36k_simsource
	prep
	hierarchy -top top
	stat
	sim -assert -q -n [expr 2**$depth_log2+4] -clock clk
}

design -reset
read_verilog -sv merged_top.v memhammer.v
hierarchy -top merged_top
prep;
opt_dff;
prep -rdff;
flatten;

synth_quicklogic -family qlf_k6n10f -run map_bram

dump t:TDP36K

select -assert-none {t:$mem_v2} {t:$mem}
select -assert-count 1 t:TDP36K
select -assert-count 1 t:TDP36K a:is_split=1 %i

read_verilog {*}$tdp36k_simsource
prep
hierarchy -top merged_top
stat
sim -assert -q -n [expr 2**11+4] -clock clk
