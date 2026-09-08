# -rel_ip_blif: link annotated IP netlists over their blackbox stubs.
# Needs a read_blif that accepts .attr on .names (Aurora's Yosys has it).

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

proc file_text {path} {
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    return $txt
}

# Fail unless exactly `expected` lines of `txt` match the regexp `pattern`.
proc assert_lines {what txt pattern expected} {
    set n [regexp -all -line -- $pattern $txt]
    if {$n != $expected} {
        error "$what: expected $expected line(s) matching {$pattern}, found $n"
    }
}

proc assert_clocks {what path} {
    set txt [string trim [file_text $path]]
    if {$txt ne "clk"} {
        error "$what: .clocks file should name exactly the clock 'clk', got '$txt'"
    }
}

read_verilog $::env(DESIGN_TOP).v
design -save read

set blif [test_output_path "rel_ip_blif.eblif"]
set clocks [test_output_path "rel_ip_blif.clocks"]

# -----------------------------------------------------------------------------
# 1. Catalog-style IP file (a single .model), two instances.
# -----------------------------------------------------------------------------
synth_quicklogic -family qlf_k6n10f -top top -rel_ip_blif rel_ip.eblif -blif $blif -clocks_file $clocks

# In memory: each annotated cell carries its instance's macro name; keep is gone.
yosys cd top
select -assert-count 4 a:REL_MACRO_TYPE
select -assert-count 2 a:REL_MACRO_NAME=u_ip0
select -assert-count 2 a:REL_MACRO_NAME=u_ip1
select -assert-none a:keep
yosys cd

# In the BLIF: the annotations and nothing else.
set txt [file_text $blif]
assert_lines "macro name u_ip0" $txt {^\.attr REL_MACRO_NAME "u_ip0"$} 2
assert_lines "macro name u_ip1" $txt {^\.attr REL_MACRO_NAME "u_ip1"$} 2
assert_lines "macro type"       $txt {^\.attr REL_MACRO_TYPE "TEST_MACRO"$} 4
assert_lines "site path"        $txt {^\.attr SITE_PATH "} 2
assert_lines "other attributes" $txt {^\.attr (?!REL_|SITE_PATH )} 0
# One .blackbox .model per primitive in use.
assert_lines "dffre model" $txt {^\.model dffre$} 1
if {![regexp {\.model dffre\n\.inputs [^\n]*\n\.outputs [^\n]*\n\.blackbox\n} $txt]} {
    error "the dffre .model section is not a plain .blackbox declaration"
}
# The clock is found through the IP's flip-flops and the user's.
assert_clocks "single-model IP" $clocks

# -----------------------------------------------------------------------------
# 2. IP file with a .blackbox declaration of dffre, in a design whose only
#    clock sinks are the IP's flip-flops. If the link replaced the library's
#    dffre, the .clocks file would come out empty.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top top_ip_only -rel_ip_blif rel_ip_embedded.eblif -blif $blif -clocks_file $clocks
assert_clocks "embedded-model IP" $clocks
set txt [file_text $blif]
assert_lines "dffre model" $txt {^\.model dffre$} 1
assert_lines "macro name u_ip0" $txt {^\.attr REL_MACRO_NAME "u_ip0"$} 2
assert_lines "macro name u_ip1" $txt {^\.attr REL_MACRO_NAME "u_ip1"$} 2

# -----------------------------------------------------------------------------
# 3. A user LUT over two constant IP outputs folds to a constant instead of
#    reaching VPR with the same net on two pins.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top top_const -rel_ip_blif rel_ip.eblif -blif $blif -clocks_file $clocks
set txt [file_text $blif]
assert_lines "kk is constant" $txt {^\.names \$false kk$} 1

# -----------------------------------------------------------------------------
# 4. An instance nothing reads is swept, as VPR would sweep it; its macro
#    contributes no atoms rather than atoms VPR no longer has.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top top_dead -rel_ip_blif rel_ip.eblif -blif $blif -clocks_file $clocks
set txt [file_text $blif]
assert_lines "macro name u_ip0" $txt {^\.attr REL_MACRO_NAME "u_ip0"$} 2
assert_lines "macro name u_ip1" $txt {^\.attr REL_MACRO_NAME "u_ip1"$} 0

# -----------------------------------------------------------------------------
# 5. The DSP-V4 flow rewrites the BLIF through a read-back; the annotations
#    must survive it unchanged.
# -----------------------------------------------------------------------------
design -load read
synth_quicklogic -family qlf_k6n10f -top top -dspv4 -rel_ip_blif rel_ip.eblif -blif $blif -clocks_file $clocks
set txt [file_text $blif]
assert_lines "macro name u_ip0" $txt {^\.attr REL_MACRO_NAME "u_ip0"$} 2
assert_lines "macro name u_ip1" $txt {^\.attr REL_MACRO_NAME "u_ip1"$} 2
assert_lines "other attributes" $txt {^\.attr (?!REL_|SITE_PATH )} 0
assert_clocks "dspv4 flow" $clocks

# The help text must be reachable (it used to crash); checked by the Makefile.
help synth_quicklogic
