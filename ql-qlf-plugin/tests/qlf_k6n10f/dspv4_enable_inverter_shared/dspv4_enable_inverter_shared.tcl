# dspv4_enable_inverter_shared -- one inverter per enable signal, not per CE pin.
#
# Two phases. The inverter count has to be read right after ql_dspv4: a later
# opt merges identical inverters and hides the difference, so the count in the
# finished netlist cannot tell the two behaviours apart. The staged run uses
# the passes the flow runs ahead of ql_dspv4.
#
# The full run then checks the outcome. ql_dsp4_check counts enable nets; the
# Makefile requires that its "distinct clock enables" warning is absent.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_enable_inverter_shared.v
design -save rtl

# One module, up to ql_dspv4, with the inverter count asserted.
proc staged {top inverters} {
    design -load rtl
    hierarchy -top $top
    yosys proc
    yosys flatten
    yosys opt
    yosys fsm
    yosys opt
    yosys wreduce
    yosys peepopt
    yosys opt_clean
    yosys share
    yosys wreduce
    ql_dspv4
    yosys cd $top
    select -assert-count 1 t:QL_DSP4
    select -assert-count $inverters t:\$not
    yosys cd
}

staged dspv4_inverter_shared 1
staged dspv4_inverter_pairs 2

# The full flow, for the outcome.
design -load rtl
hierarchy -top dspv4_inverter_shared
$PASS_NAME -family qlf_k6n10f -top dspv4_inverter_shared -dspv4 -no_abc9 -lib_path $LIB/
yosys cd dspv4_inverter_shared
select -assert-none t:QL_DSP4
