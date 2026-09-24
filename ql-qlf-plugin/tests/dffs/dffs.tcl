yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

# =============================================================================
# qlf_k6n10f (with synchronous S/R flip-flops)

read_verilog $::env(DESIGN_TOP).v
design -save read

# DFF
hierarchy -top my_dff
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dff
design -load postopt
yosys cd my_dff
stat
select -assert-count 1 t:sdffre

# DFFN
design -load read
hierarchy -top my_dffn
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffn
design -load postopt
yosys cd my_dffn
stat
select -assert-count 1 t:sdffnre

# DFFSRE from DFFR_N
design -load read
hierarchy -top my_dffr_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffr_n
design -load postopt
yosys cd my_dffr_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFR_P
design -load read
hierarchy -top my_dffr_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffr_p
design -load postopt
yosys cd my_dffr_p
stat
select -assert-count 1 t:dffre
select -assert-count 1 t:\$lut

# DFFSRE from DFFRE_N
design -load read
hierarchy -top my_dffre_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffre_n
design -load postopt
yosys cd my_dffre_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFRE_P
design -load read
hierarchy -top my_dffre_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffre_p
design -load postopt
yosys cd my_dffre_p
stat
select -assert-count 1 t:dffre
select -assert-count 1 t:\$lut

# DFFSRE from DFFS_N
design -load read
hierarchy -top my_dffs_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffs_n
design -load postopt
yosys cd my_dffs_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFS_P
design -load read
hierarchy -top my_dffs_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffs_p
design -load postopt
yosys cd my_dffs_p
stat
select -assert-count 1 t:dffre
select -assert-count 3 t:\$lut

# DFFSRE from DFFSE_N
design -load read
hierarchy -top my_dffse_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffse_n
design -load postopt
yosys cd my_dffse_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFSE_P
design -load read
hierarchy -top my_dffse_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffse_p
design -load postopt
yosys cd my_dffse_p
stat
select -assert-count 1 t:dffre
select -assert-count 3 t:\$lut

# SDFFSRE from SDFFR_N
design -load read
hierarchy -top my_sdffr_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffr_n
design -load postopt
yosys cd my_sdffr_n
stat
select -assert-count 1 t:sdffre

# SDFFSRE from SDFFR_P
design -load read
hierarchy -top my_sdffr_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffr_p
design -load postopt
yosys cd my_sdffr_p
stat
select -assert-count 1 t:sdffre
select -assert-count 1 t:\$lut

# SDFFSRE from SDFFS_N
design -load read
hierarchy -top my_sdffs_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffs_n
design -load postopt
yosys cd my_sdffs_n
stat
select -assert-count 1 t:sdffre

# SDFFSRE from SDFFS_P
design -load read
hierarchy -top my_sdffs_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffs_p
design -load postopt
yosys cd my_sdffs_p
stat
select -assert-count 1 t:sdffre
select -assert-count 3 t:\$lut

# SDFFNSRE from SDFFNR_N
design -load read
hierarchy -top my_sdffnr_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffnr_n
design -load postopt
yosys cd my_sdffnr_n
stat
select -assert-count 1 t:sdffnre

# SDFFNSRE from SDFFRN_P
design -load read
hierarchy -top my_sdffnr_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffnr_p
design -load postopt
yosys cd my_sdffnr_p
stat
select -assert-count 1 t:sdffnre
select -assert-count 1 t:\$lut

# SDFFNSRE from SDFFNS_N
design -load read
hierarchy -top my_sdffns_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffns_n
design -load postopt
yosys cd my_sdffns_n
stat
select -assert-count 1 t:sdffnre

# SDFFSRE from SDFFNS_P
design -load read
hierarchy -top my_sdffns_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_sdffns_p
design -load postopt
yosys cd my_sdffns_p
stat
select -assert-count 1 t:sdffnre
select -assert-count 3 t:\$lut

# LATCH and LATCHN moved to qlf_k6n10f/latches_k6n10f.

## LATCHSRE from LATCHR_N
#design -load read
#hierarchy -top my_latchr_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchr_n
#design -load postopt
#yosys cd my_latchr_n
#stat
#select -assert-count 1 t:latchr_n
#
## LATCHSRE from LATCHR_P
#design -load read
#hierarchy -top my_latchr_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchr_p
#design -load postopt
#yosys cd my_latchr_p
#stat
#select -assert-count 1 t:latchr_p
#select -assert-count 1 t:\$lut
#
## LATCHSRE from LATCHS_N
#design -load read
#hierarchy -top my_latchs_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchs_n
#design -load postopt
#yosys cd my_latchs_n
#stat
#select -assert-count 1 t:latchs_n
#
## LATCHSRE from LATCHS_P
#design -load read
#hierarchy -top my_latchs_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchs_p
#design -load postopt
#yosys cd my_latchs_p
#stat
#select -assert-count 1 t:latchs_p
#select -assert-count 1 t:\$lut
#
#
## LATCHSRE from LATCHNR_N
#design -load read
#hierarchy -top my_latchnr_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchnr_n
#design -load postopt
#yosys cd my_latchnr_n
#stat
#select -assert-count 1 t:latchnr_n
#
## LATCHSRE from LATCHNR_P
#design -load read
#hierarchy -top my_latchnr_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchnr_p
#design -load postopt
#yosys cd my_latchnr_p
#stat
#select -assert-count 1 t:latchnr_p
#select -assert-count 1 t:\$lut
#
## LATCHSRE from LATCHNS_N
#design -load read
#hierarchy -top my_latchns_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchns_n
#design -load postopt
#yosys cd my_latchns_n
#stat
#select -assert-count 1 t:latchns_n
#
## LATCHSRE from LATCHNS_P
#design -load read
#hierarchy -top my_latchns_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchns_p
#design -load postopt
#yosys cd my_latchns_p
#stat
#select -assert-count 1 t:latchns_p
#select -assert-count 1 t:\$lut

design -reset

# =============================================================================
# qlf_k6n10f (no synchronous S/R flip-flops)

read_verilog $::env(DESIGN_TOP).v
design -save read

# DFF
hierarchy -top my_dff
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dff -nosdff
design -load postopt
yosys cd my_dff
stat
select -assert-count 1 t:dffre

# DFFN
design -load read
hierarchy -top my_dffn
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffn -nosdff
design -load postopt
yosys cd my_dffn
stat
select -assert-count 1 t:dffnre

# DFFSRE from DFFR_N
design -load read
hierarchy -top my_dffr_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffr_n -nosdff
design -load postopt
yosys cd my_dffr_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFR_P
design -load read
hierarchy -top my_dffr_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffr_p -nosdff
design -load postopt
yosys cd my_dffr_p
stat
select -assert-count 1 t:dffre
select -assert-count 1 t:\$lut

# DFFSRE from DFFRE_N
design -load read
hierarchy -top my_dffre_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffre_n -nosdff
design -load postopt
yosys cd my_dffre_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFRE_P
design -load read
hierarchy -top my_dffre_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffre_p -nosdff
design -load postopt
yosys cd my_dffre_p
stat
select -assert-count 1 t:dffre
select -assert-count 1 t:\$lut

# DFFSRE from DFFS_N
design -load read
hierarchy -top my_dffs_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffs_n -nosdff
design -load postopt
yosys cd my_dffs_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFS_P
design -load read
hierarchy -top my_dffs_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffs_p -nosdff
design -load postopt
yosys cd my_dffs_p
stat
select -assert-count 1 t:dffre
select -assert-count 3 t:\$lut

# DFFSRE from DFFSE_N
design -load read
hierarchy -top my_dffse_n
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffse_n -nosdff
design -load postopt
yosys cd my_dffse_n
stat
select -assert-count 1 t:dffre

# DFFSRE from DFFSE_P
design -load read
hierarchy -top my_dffse_p
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_dffse_p -nosdff
design -load postopt
yosys cd my_dffse_p
stat
select -assert-count 1 t:dffre
select -assert-count 3 t:\$lut

# LATCH and LATCHN moved to qlf_k6n10f/latches_k6n10f.

## LATCHSRE from LATCHR_N
#design -load read
#hierarchy -top my_latchr_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchr_n -nosdff
#design -load postopt
#yosys cd my_latchr_n
#stat
#select -assert-count 1 t:latchr_n
#
## LATCHSRE from LATCHR_P
#design -load read
#hierarchy -top my_latchr_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchr_p -nosdff
#design -load postopt
#yosys cd my_latchr_p
#stat
#select -assert-count 1 t:latchr_p
#select -assert-count 1 t:\$lut
#
## LATCHSRE from LATCHS_N
#design -load read
#hierarchy -top my_latchs_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchs_n -nosdff
#design -load postopt
#yosys cd my_latchs_n
#stat
#select -assert-count 1 t:latchs_n
#
## LATCHSRE from LATCHS_P
#design -load read
#hierarchy -top my_latchs_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchs_p -nosdff
#design -load postopt
#yosys cd my_latchs_p
#stat
#select -assert-count 1 t:latchs_p
#select -assert-count 1 t:\$lut
#
#
## LATCHSRE from LATCHNR_N
#design -load read
#hierarchy -top my_latchnr_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchnr_n -nosdff
#design -load postopt
#yosys cd my_latchnr_n
#stat
#select -assert-count 1 t:latchnr_n
#
## LATCHSRE from LATCHNR_P
#design -load read
#hierarchy -top my_latchnr_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchnr_p -nosdff
#design -load postopt
#yosys cd my_latchnr_p
#stat
#select -assert-count 1 t:latchnr_p
#select -assert-count 1 t:\$lut
#
## LATCHSRE from LATCHNS_N
#design -load read
#hierarchy -top my_latchns_n
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchns_n -nosdff
#design -load postopt
#yosys cd my_latchns_n
#stat
#select -assert-count 1 t:latchns_n
#
## LATCHSRE from LATCHNS_P
#design -load read
#hierarchy -top my_latchns_p
#yosys proc
#equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchns_p -nosdff
#design -load postopt
#yosys cd my_latchns_p
#stat
#select -assert-count 1 t:latchns_p
#select -assert-count 1 t:\$lut
