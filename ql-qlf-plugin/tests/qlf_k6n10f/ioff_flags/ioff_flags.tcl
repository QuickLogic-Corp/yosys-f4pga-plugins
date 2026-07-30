# Flag behaviour matrix -- test-plan section 6 (REQ-C2, REQ-D1, REQ-D3).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

source ../ioff_utils.tcl

read_verilog $::env(DESIGN_TOP).v
design -save read

# -----------------------------------------------------------------------------
# 6.1 / 6.2  Without -ioff nothing is promoted. Promotion is the only difference
#            the flag makes, and the flag's default is unchanged -- adding
#            io_sdffr support must not start promoting for designs that do not
#            ask for it.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top flag_rst
yosys cd flag_rst
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:sdffre

design -load read
synth_quicklogic -family qlf_k6n10f -top flag_none
yosys cd flag_none
stat
select -assert-count 0 t:dff
select -assert-count 1 t:sdffre

# With -ioff, the same two designs promote.
design -load read
synth_quicklogic -family qlf_k6n10f -top flag_rst -ioff
yosys cd flag_rst
select -assert-count 1 t:io_sdffr

design -load read
synth_quicklogic -family qlf_k6n10f -top flag_none -ioff
yosys cd flag_none
select -assert-count 1 t:dff

# -----------------------------------------------------------------------------
# 6.3  -ioff -nosdff must not error. With no $_SDFF* target available,
#      dfflegalize emulates the synchronous reset with a D-side LUT, so the
#      reset-carrying register arrives as a *resetless* dffre whose D is no
#      longer a top-level input -- it is simply not a boundary register any
#      more, and no io_sdffr can be produced. The genuinely resetless design
#      still promotes.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top flag_rst -ioff -nosdff
yosys cd flag_rst
stat
select -assert-count 0 t:io_sdffr
select -assert-count 0 t:io_sdffnr
select -assert-count 1 t:dffre

design -load read
synth_quicklogic -family qlf_k6n10f -top flag_none -ioff -nosdff
yosys cd flag_none
stat
select -assert-count 0 t:io_sdffr
select -assert-count 1 t:dff

# -----------------------------------------------------------------------------
# 6.4  -ioff -no_ff_map must not error either. With FF techmap off, none of the
#      four source cell types exist, so the pass has nothing to match.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top flag_rst -ioff -no_ff_map
yosys cd flag_rst
stat
select -assert-count 0 t:io_sdffr
select -assert-count 0 t:io_sdffnr
