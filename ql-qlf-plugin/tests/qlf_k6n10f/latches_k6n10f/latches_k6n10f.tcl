# Split out of dffs; fails until the owner confirms qlf_k6n10f dropped latches on purpose.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
design -save read

# =============================================================================
# qlf_k6n10f (with synchronous S/R flip-flops)

# LATCH
design -load read
hierarchy -top my_latch
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latch
design -load postopt
yosys cd my_latch
stat
select -assert-count 1 t:latchsre

# LATCHN
design -load read
hierarchy -top my_latchn
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchn
design -load postopt
yosys cd my_latchn
stat
select -assert-count 1 t:latchnsre

# =============================================================================
# qlf_k6n10f (no synchronous S/R flip-flops)

# LATCH
design -load read
hierarchy -top my_latch
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latch -nosdff
design -load postopt
yosys cd my_latch
stat
select -assert-count 1 t:latchsre

# LATCHN
design -load read
hierarchy -top my_latchn
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchn -nosdff
design -load postopt
yosys cd my_latchn
stat
select -assert-count 1 t:latchnsre
