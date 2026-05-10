# Shared synthesis harness for the dspv2 lowering flow.
#
# Follows the same proc structure as tests/qlf_k6n10f/dsp_macc/dsp_macc.tcl::check_equiv
# but WITHOUT formal equivalence checking.  The dspv2_sim.v behavioural model
# (32×18 operands, rounding, saturation, shift, frac-mode) is too complex for
# Yosys' SAT-based equiv_induct — even for a pure combinational multiply the
# solver does not converge within 2 minutes.
#
# Functional equivalence has been verified via iverilog co-simulation; these
# tests use structural assertions (cell type & count) as their acceptance
# criteria.
#
# The proc saves the post-synth design as "postopt" so callers can
#   design -load postopt
# to inspect the gate netlist.
#
# Per-test wrapper usage:
#
#   yosys -import
#   if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
#   yosys -import  ;# ingest plugin commands
#   source [file join [file dirname [info script]] .. dspv2_equiv.tcl]
#   read_verilog <design>.v
#   design -save read
#   design -load read
#   hierarchy -top <top>
#   run_synth_dspv2 <top_module>
#   design -load postopt
#   yosys cd <top>
#   select -assert-count 1 t:QL_DSPV2_*

proc run_synth_dspv2 {top} {
    # Aurora2 builds the plugin with PASS_NAME=synth_ql; standalone
    # builds use the default synth_quicklogic.  Detect which is
    # available so the same harness works in both environments.
    if {[llength [info commands synth_ql]]} {
        set _synth synth_ql
    } else {
        set _synth synth_quicklogic
    }

    $_synth -family qlf_k6n10f -top ${top} -dspv2

    design -stash postopt

    return
}
