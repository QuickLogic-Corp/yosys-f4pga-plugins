# dspv4_trunc -- a product the RTL truncated must not fuse with anything that
# reads the result above the cut, and must still fuse with anything that does
# not. One multiply per shape; see dspv4_trunc.v for what each shape is.
yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import

set PASS_NAME synth_quicklogic
if { [info commands synth_ql] != {} } { set PASS_NAME synth_ql }

# The DSP-V4 collateral ships with the plugin, so no device_data tree is
# needed. -lib_path appends the family name, so it points at the plugin root.
set LIB [file normalize [file join [file dirname [info script]] .. .. ..]]

read_verilog dspv4_trunc.v
design -save read

# Synthesise one shape and check what every shape shares: the multiply is in a
# DSP and no soft arithmetic cell survives. The shape's own assertions follow
# each call, with the design still inside that module.
proc shape {name} {
    global PASS_NAME LIB
    design -load read
    hierarchy -top $name
    $PASS_NAME -family qlf_k6n10f -top $name -dspv4 -no_abc9 -lib_path $LIB/
    yosys cd $name
    check -assert
    select -assert-count 1 t:QL_DSP4_MULT
    select -assert-count 0 t:\$mul
    select -assert-count 0 t:\$add
    select -assert-count 0 t:\$sub
}

# ---- Refused: the addition stays in fabric, so a carry chain survives. -----

shape dspv4_trunc_add
select -assert-min 1 t:adder_carry

shape dspv4_trunc_sub
select -assert-min 1 t:adder_carry

shape dspv4_trunc_rsub
select -assert-min 1 t:adder_carry

shape dspv4_trunc_carry
select -assert-min 1 t:adder_carry

shape dspv4_trunc_macc
select -assert-min 1 t:adder_carry
# The accumulator stayed in fabric.
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-min 1 t:sdffre

shape dspv4_trunc_mreg
select -assert-min 1 t:adder_carry
# The product register went into P, not M.
select -assert-count 0 t:QL_DSP4_M_DFFR_50
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64

shape dspv4_trunc_macc_c
select -assert-min 1 t:adder_carry
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64

shape dspv4_trunc_regout
select -assert-min 1 t:adder_carry
select -assert-count 0 t:QL_DSP4_ACC_DFFRE_64
select -assert-min 1 t:sdffre

# ---- Still folded: nothing reads above the cut, so no soft adder. ---------

shape dspv4_trunc_narrow
select -assert-count 0 t:adder_carry

shape dspv4_trunc_narrow_macc
select -assert-count 0 t:adder_carry
select -assert-count 1 t:QL_DSP4_ACC_DFFRE_64

shape dspv4_trunc_narrow_mreg
select -assert-count 0 t:adder_carry
select -assert-count 1 t:QL_DSP4_M_DFFR_50
