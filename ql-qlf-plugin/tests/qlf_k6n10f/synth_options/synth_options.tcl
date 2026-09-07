# synth_quicklogic option handling. Every option runs on one small design and
# is checked through what it changes in the result, so a change to the option
# parser or to an option's effect is caught here.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
design -save rtl

# Synthesize the saved RTL with the given extra options.
proc synth {args} {
    design -load rtl
    eval synth_quicklogic -family qlf_k6n10f -top top $args
    yosys cd top
}

# Same, capturing the synthesis log in `logfile` for options only visible there.
proc synth_logged {logfile args} {
    design -load rtl
    eval tee -q -o $logfile synth_quicklogic -family qlf_k6n10f -top top $args
    yosys cd top
}

proc file_text {path} {
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

proc assert_file {what path} {
    if {![file exists $path] || [file size $path] == 0} {
        error "$what: $path is missing or empty"
    }
}

proc assert_log {what logfile pattern expected} {
    set n [regexp -all -line -- $pattern [file_text $logfile]]
    if {($expected && $n == 0) || (!$expected && $n > 0)} {
        error "$what: {$pattern} found $n time(s) in $logfile"
    }
}

# Reference result.
synth
select -assert-count 1 t:QL_DSP2_MULT
select -assert-count 1 t:TDP36K
select -assert-count 17 t:adder_carry
select -assert-count 48 t:sdffre
select -assert-none t:\$_*
# One net drives register enable pins: the `en` logic of q.
select -assert-count 1 t:sdffre %x1:+\[E\] t:sdffre %d

# Inference switches.
synth -no_dsp
select -assert-none t:QL_DSP2_MULT
select -assert-count 1 t:TDP36K

synth -no_adder
select -assert-none t:adder_carry
select -assert-count 1 t:QL_DSP2_MULT

synth -no_bram
select -assert-none t:TDP36K
select -assert-count 1 t:QL_DSP2_MULT

# Flip-flop options.
synth -nosdff
select -assert-none t:sdffre
select -assert-count 48 t:dffre

synth -no_ffenable
select -assert-count 48 t:sdffre
select -assert-none t:sdffre %x1:+\[E\] t:sdffre %d

# -mince_num N drops enables shared by fewer than N registers; q has 16.
synth -mince_num 32
select -assert-none t:sdffre %x1:+\[E\] t:sdffre %d
synth -mince_num 4
select -assert-count 1 t:sdffre %x1:+\[E\] t:sdffre %d

synth -no_ff_map
select -assert-none t:sdffre
select -assert-count 32 t:\$_DFF_P_
select -assert-count 16 t:\$_SDFFE_PP0P_

# BRAM typing.
synth -bram_types
select -assert-none t:TDP36K
select -assert-count 1 t:TDP36K_BRAM_A_X18_B_X18_nonsplit
# ECC typing has no variant for an 18-bit memory: the BRAM stays untyped.
synth -bram_types -bramecc
select -assert-count 1 t:TDP36K
select -assert-none t:TDP36K_BRAM_A_X18_B_X18_nonsplit

# DSP variants.
synth -dspv2
select -assert-none t:QL_DSP2_MULT
synth -dspv4
select -assert-none t:QL_DSP2_MULT
select -assert-count 1 t:QL_DSP4_MULT
synth -use_dsp_cfg_params
select -assert-none t:QL_DSP2_MULT
select -assert-count 1 t:QL_DSP3_MULT

# LUT mapping options, visible in the log or as unmapped gates.
set log [test_output_path "synth_options_abc.log"]
synth_logged $log -no_abc9
assert_log "-no_abc9" $log {Executing ABC9 pass} 0
assert_log "-no_abc9" $log {Executing ABC pass} 1
select -assert-count 1 t:QL_DSP2_MULT
select -assert-none t:\$_*

synth_logged $log -no_abc9 -custom_abc_script custom_abc.scr
assert_log "-custom_abc_script" $log {custom abc script for the options test} 1
select -assert-none t:\$_*

synth -no_abc_opt
select -assert-none t:\$lut
select -assert-count 17 t:\$_XOR_

synth -no_opt
select -assert-none t:\$lut
select -assert-min 1 t:\$_AND_

# Paths and outputs.
synth -lib_path +/quicklogic/
select -assert-count 1 t:QL_DSP2_MULT

set blif [test_output_path "synth_options.blif"]
set clocks [test_output_path "synth_options.clocks"]
set edif [test_output_path "synth_options.edif"]
set vlog [test_output_path "synth_options_out.v"]
file delete $blif $clocks $edif $vlog
synth -blif $blif -clocks_file $clocks -edif $edif -verilog $vlog
assert_file "-blif" $blif
assert_file "-clocks_file" $clocks
assert_file "-edif" $edif
assert_file "-verilog" $vlog
if {[lsearch -exact [split [string trim [file_text $clocks]] "\n"] clk] < 0} {
    error "-clocks_file: clk is not listed in $clocks"
}

# -run: only the begin label runs, so the design stays at the RTLIL level.
synth -run begin:prepare
select -assert-count 1 t:\$mul
select -assert-count 1 t:\$add
select -assert-none t:\$lut

# Options whose full flow needs Aurora's environment (-de: the DE binary and
# abc-rs; -no_tdpram: a library with the SDP36K model) or a Synplify netlist
# (-synplify). Accepted, and the flow up to `prepare` runs.
synth -de delay -run begin:prepare
select -assert-count 1 t:\$mul
synth -no_tdpram -run begin:prepare
select -assert-count 1 t:\$mul
synth -synplify -run begin:prepare
select -assert-count 1 t:\$mul

# Rejected command lines.
design -load rtl
foreach bad {
    {synth_quicklogic -family qlf_k6n10f -top top -bogus}
    {synth_quicklogic -family qlf_k6n10f -top top -blif}
    {synth_quicklogic -family qlf_k6n10f -top top -mince_num}
    {synth_quicklogic -family nope -top top}
} {
    if {![catch {eval $bad} msg]} {
        error "accepted a command line that must be rejected: $bad"
    }
}
