# Copyright 2020-2022 F4PGA Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

# The bram test will be enable in a future PR after it's been fixed.

TESTS = \
	dffs \
	shreg \
	full_adder \
	qlf_k6n10f/dsp_mult \
	qlf_k6n10f/dsp_simd \
	qlf_k6n10f/dsp_macc \
	qlf_k6n10f/dspv4_mult \
	qlf_k6n10f/dspv4_mult_add \
	qlf_k6n10f/dspv4_mult_add_chain \
	qlf_k6n10f/dspv4_mult_regout \
	qlf_k6n10f/dspv4_mult_regin \
	qlf_k6n10f/dspv4_mult_regin_concat \
	qlf_k6n10f/dspv4_mult_sub \
	qlf_k6n10f/dspv4_macc \
	qlf_k6n10f/dspv4_mult_fanout \
	qlf_k6n10f/dspv4_mult_wide \
	qlf_k6n10f/dspv4_mult_wide_result \
	qlf_k6n10f/dspv4_mult_wide_regin \
	qlf_k6n10f/dspv4_mult_negedge \
	qlf_k6n10f/dspv4_mult_keep \
	qlf_k6n10f/dspv4_mult_init \
	qlf_k6n10f/dspv4_mult_mreg \
	qlf_k6n10f/dspv4_mult_mreg_narrow \
	qlf_k6n10f/dspv4_mult_shared_chain \
	qlf_k6n10f/dspv4_mult_regout2 \
	qlf_k6n10f/dspv4_macc_sub \
	qlf_k6n10f/dspv4_macc_rsub \
	qlf_k6n10f/dspv4_macc_areset \
	qlf_k6n10f/dspv4_mult_rsub_c \
	qlf_k6n10f/dspv4_mult_shared_operand \
	qlf_k6n10f/dspv4_macc_dup \
	qlf_k6n10f/dspv4_mult_add_evencoef \
	qlf_k6n10f/dspv4_mult_add_self \
	qlf_k6n10f/dspv4_mult_mreg_add_self \
	qlf_k6n10f/dspv4_trunc \
	qlf_k6n10f/dspv4_mult_no_opt \
	qlf_k6n10f/dspv4_preadd_widths \
	qlf_k6n10f/dspv4_preadd_refused \
	qlf_k6n10f/dspv4_preadd_modes \
	qlf_k6n10f/dspv4_preadd_sub_fused \
	qlf_k6n10f/dspv4_preadd_a_macc \
	qlf_k6n10f/dspv4_preadd_sub_unsigned \
	qlf_k6n10f/dspv4_mult_reg_pad \
	qlf_k6n10f/dspv4_xpath \
	qlf_k6n10f/dspv4_xpath_refused \
	qlf_k6n10f/dspv4_preadd_both \
	qlf_k6n10f/dspv4_preadd_square \
	qlf_k6n10f/dspv4_double_feed_scope \
	qlf_k6n10f/dspv4_preadd_preg_wrap \
	qlf_k6n10f/dspv4_preadd_adreg_trunc \
	qlf_k6n10f/dspv4_preadd_regs \
	qlf_k6n10f/dspv4_enable_inverter_shared \
	qlf_k6n10f/dspv4_techmap_refused_stops \
	qlf_k6n10f/dspv4_techmap_twin_maps \
	qlf_k6n10f/dspv4_techmap_reason \
	qlf_k6n10f/dspv4_techmap_refused_drc \
	qlf_k6n10f/dspv4_techmap_twin_drc_maps \
	qlf_k6n10f/dspv4_synplify_gnd_cin_folds \
	qlf_k6n10f/dspv4_synplify_live_cin_keeps_m \
	qlf_k6n10f/dspv4_enable_tied_high_evicts \
	qlf_k6n10f/dspv4_enable_tied_high_check \
	qlf_k6n10f/dspv4_preadd_adreg_rst \
	qlf_k6n10f/dspv4_preadd_adreg_evict \
	qlf_k6n10f/dspv4_leftover_reasons \
	qlf_k6n10f/dspv4_casc_flags \
	qlf_k6n10f/dspv4_casc_chain_max_refused \
	qlf_k6n10f/dspv4_casc_links \
	qlf_k6n10f/dspv4_casc_refused \
	qlf_k6n10f/dspv4_casc_addend \
	qlf_k6n10f/dspv4_casc_addend_refused \
	qlf_k6n10f/dspv4_casc_loop_no_register \
	qlf_k6n10f/dsp_madd \
	qlf_k6n10f/ioff \
	qlf_k6n10f/sdffr_inst \
	qlf_k6n10f/ioff_rst \
	qlf_k6n10f/ioff_pol \
	qlf_k6n10f/ioff_flags \
	qlf_k6n10f/ioff_blif \
	qlf_k6n10f/io_translate \
	qlf_k6n10f/rel_ip_blif \
	qlf_k6n10f/rel_ip_blif_noannot \
	qlf_k6n10f/rel_ip_blif_notflat \
	qlf_k6n10f/rel_ip_blif_unquoted \
	qlf_k6n10f/rel_ip_blif_badstub \
	qlf_k6n10f/rel_ip_blif_noprim \
	qlf_k6n10f/synth_options \
	qlf_k6n10f/latches_k6n10f

SIM_TESTS = \
     qlf_k6n10f/sim_dsp_mult_cfg_ports \
     qlf_k6n10f/sim_dsp_mult_cfg_params \
     qlf_k6n10f/sim_dsp_mult_r_cfg_ports \
     qlf_k6n10f/sim_dsp_mult_r_cfg_params \
     qlf_k6n10f/sim_dsp_fir_cfg_ports \
     qlf_k6n10f/sim_dsp_fir_cfg_params \
     qlf_k6n10f/sim_dsp_simd_cfg_ports \
     qlf_k6n10f/sim_dsp_simd_cfg_params \
     qlf_k6n10f/sim_tc36fifo

# Those tests perform synthesis and simulation of synthesis results
POST_SYNTH_SIM_TESTS = \
     qlf_k6n10f/asymmetric_bram36k_sfifo \
     qlf_k6n10f/asymmetric_bram36k_afifo \
     qlf_k6n10f/bram36k_sfifo \
     qlf_k6n10f/bram36k_afifo \
     qlf_k6n10f/bram18k_afifo \
     qlf_k6n10f/bram18k_sfifo \
     qlf_k6n10f/bram18k_tdp \
     qlf_k6n10f/bram36k_tdp \
     qlf_k6n10f/bram18k_sdp \
     qlf_k6n10f/bram36k_sdp \
     qlf_k6n10f/asymmetric_bram36k_sdp \
     qlf_k6n10f/asymmetric_bram18k_sdp \
     qlf_k6n10f/bram_tdp \
     qlf_k6n10f/bram_sdp \
     qlf_k6n10f/bram_tdp_split \
     qlf_k6n10f/bram_sdp_split \
     qlf_k6n10f/dsp_mult_post_synth_sim \
     qlf_k6n10f/dsp_simd_post_synth_sim \
     qlf_k6n10f/bram_asymmetric_wider_write \
     qlf_k6n10f/bram_asymmetric_wider_read \
     qlf_k6n10f/dspv4_port_reg_post_synth_sim \
     qlf_k6n10f/dspv4_macc_c_order_post_synth_sim \
     qlf_k6n10f/dspv4_macc_c_refused_post_synth_sim \
     qlf_k6n10f/dspv4_mreg_rst_post_synth_sim \
     qlf_k6n10f/dspv4_preg_rst_post_synth_sim \
     qlf_k6n10f/dspv4_preadd_width_post_synth_sim \
     qlf_k6n10f/dspv4_operand_ext_post_synth_sim

# Synthesis-side copies of cells that dspv2_sim.v and dspv4_leaves_sim.v already model.
SIM_LIBS_EXCLUDE = QL_DSPV2.v QL_DSP4_leaves.v

include $(shell pwd)/../../Makefile_test.common

qlf_k6n10f-dspv4_mult_verify = true
qlf_k6n10f-dspv4_mult_add_verify = true
qlf_k6n10f-dspv4_mult_add_chain_verify = true
qlf_k6n10f-dspv4_mult_regout_verify = true
qlf_k6n10f-dspv4_mult_regin_verify = true
qlf_k6n10f-dspv4_mult_sub_verify = true
qlf_k6n10f-dspv4_macc_verify = true

# The 36 flops this design is expected to keep have to be explained, not just
# counted. A pass that says nothing about a result register it declined reads
# exactly like one whose pattern never saw it.
qlf_k6n10f-dspv4_macc_dup_verify = grep -q 'the DSP has no register stage after P' qlf_k6n10f/dspv4_macc_dup/dspv4_macc_dup.log

# Which mode the pass chose. The cell counts in the .tcl cannot tell
# PREADD_A_MULT_B from PREADD_B_MULT_A -- both emit one QL_DSP4_PREADD and one
# QL_DSP4_MULT -- so without these the A/B decision is untested. A refused
# shape must report MULT, not a PREADD mode: that is what says the guard
# refused rather than folded something it should not have.
qlf_k6n10f-dspv4_preadd_sub_unsigned_verify = grep -q 'modes inferred:.*PREADD_A_SUB_B x3' qlf_k6n10f/dspv4_preadd_sub_unsigned/dspv4_preadd_sub_unsigned.log
qlf_k6n10f-dspv4_preadd_sub_unsigned_verify += && grep -q 'modes inferred:.*PREADD_B_SUB_A x1' qlf_k6n10f/dspv4_preadd_sub_unsigned/dspv4_preadd_sub_unsigned.log
qlf_k6n10f-dspv4_preadd_sub_unsigned_verify += && grep -q '1 x  pre-adder: an unsigned subtract wraps where the DSP signs' qlf_k6n10f/dspv4_preadd_sub_unsigned/dspv4_preadd_sub_unsigned.log
qlf_k6n10f-dspv4_mult_reg_pad_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_mult_reg_pad/dspv4_mult_reg_pad.log
qlf_k6n10f-dspv4_mult_add_self_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_mult_add_self/dspv4_mult_add_self.log
qlf_k6n10f-dspv4_mult_add_self_verify += && grep -q '1 x  adder: it reads the multiply.s value on both operands, leaving nothing for C' qlf_k6n10f/dspv4_mult_add_self/dspv4_mult_add_self.log
qlf_k6n10f-dspv4_mult_mreg_add_self_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_mult_mreg_add_self/dspv4_mult_mreg_add_self.log
qlf_k6n10f-dspv4_mult_mreg_add_self_verify += && grep -q '1 x  adder: it reads the multiply.s value on both operands, leaving nothing for C' qlf_k6n10f/dspv4_mult_mreg_add_self/dspv4_mult_mreg_add_self.log
qlf_k6n10f-dspv4_preadd_a_macc_verify = grep -q 'modes inferred:.*PREADD_A_MACC x1' qlf_k6n10f/dspv4_preadd_a_macc/dspv4_preadd_a_macc.log
qlf_k6n10f-dspv4_preadd_a_macc_verify += && grep -q 'modes inferred:.*PREADD_A_MACC_C x1' qlf_k6n10f/dspv4_preadd_a_macc/dspv4_preadd_a_macc.log
qlf_k6n10f-dspv4_preadd_a_macc_verify += && grep -q 'modes inferred:.*PREADD_B_MACC_C x1' qlf_k6n10f/dspv4_preadd_a_macc/dspv4_preadd_a_macc.log
# Six modes in one design, so the mode line is asserted a name at a time.
# The counts cannot stand in for this: all six emit one QL_DSP4_PRESUB and
# one QL_DSP4_MULT, so swapping any two of them is invisible to a count.
qlf_k6n10f-dspv4_preadd_sub_fused_verify = grep -q 'modes inferred:.*PREADD_A_SUB_B_C x1' qlf_k6n10f/dspv4_preadd_sub_fused/dspv4_preadd_sub_fused.log
qlf_k6n10f-dspv4_preadd_sub_fused_verify += && grep -q 'modes inferred:.*PREADD_B_SUB_A_C x1' qlf_k6n10f/dspv4_preadd_sub_fused/dspv4_preadd_sub_fused.log
qlf_k6n10f-dspv4_preadd_sub_fused_verify += && grep -q 'modes inferred:.*PREADD_A_SUB_MACC x1' qlf_k6n10f/dspv4_preadd_sub_fused/dspv4_preadd_sub_fused.log
qlf_k6n10f-dspv4_preadd_sub_fused_verify += && grep -q 'modes inferred:.*PREADD_B_SUB_MACC x1' qlf_k6n10f/dspv4_preadd_sub_fused/dspv4_preadd_sub_fused.log
qlf_k6n10f-dspv4_preadd_sub_fused_verify += && grep -q 'modes inferred:.*PREADD_A_SUB_MACC_C x1' qlf_k6n10f/dspv4_preadd_sub_fused/dspv4_preadd_sub_fused.log
qlf_k6n10f-dspv4_preadd_sub_fused_verify += && grep -q 'modes inferred:.*PREADD_B_SUB_MACC_C x1' qlf_k6n10f/dspv4_preadd_sub_fused/dspv4_preadd_sub_fused.log
# (A - D) * B. Subtract is not commutative, so a swap would compute
# (D - A) * B. The SUB mode is the evidence the pass did not swap.
# Two sums, 19-bit and 9-bit. The wider one is on the A port, so taking
# the A side is the rule 'absorb the wider' working.
qlf_k6n10f-dspv4_preadd_both_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_preadd_both/dspv4_preadd_both.log
# The sum left behind is named, not just absent from the cell.
qlf_k6n10f-dspv4_preadd_both_verify += && grep -q '1 x  a second pre-adder sum stays in fabric: the cell has one pre-adder' qlf_k6n10f/dspv4_preadd_both/dspv4_preadd_both.log
qlf_k6n10f-dspv4_preadd_both_verify += && grep -q 'modes inferred: PREADD_A_SUB_B x1' qlf_k6n10f/dspv4_preadd_both/dspv4_preadd_both.log
# Squaring is refused in both blocks, so no pre-adder mode at all. The signed
# block fits one DSP. The registered one fits only in the second ql_dspv4 call,
# split over two, with its register copied into the banks (aurora2 #2807).
qlf_k6n10f-dspv4_preadd_square_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
qlf_k6n10f-dspv4_preadd_square_verify += && grep -q 'modes inferred: MULT x2' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
qlf_k6n10f-dspv4_preadd_square_verify += && grep -q '2 x  pre-adder: it feeds both multiply operands (squaring)' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
qlf_k6n10f-dspv4_preadd_square_verify += && grep -q '1 shared operand register(s) copied into a bank rather than moved; 1 became userless' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
qlf_k6n10f-dspv4_preadd_square_verify += && test -s qlf_k6n10f/dspv4_preadd_square/netlist.v
qlf_k6n10f-dspv4_preadd_square_verify += && ! grep -E -q "'[bh][0-9a-f]*x" qlf_k6n10f/dspv4_preadd_square/netlist.v
# Every cross-path shape that must fold, 48 blocks, nine modes in no fixed
# order. No block may be refused, and the four blocks that give up a register
# stage to the bank depth limit must do it for that reason, not a clock/reset
# mismatch.
qlf_k6n10f-dspv4_xpath_verify = grep -E -q 'modes inferred: [^,]+(, [^,]+){8}$$' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*XPATH_A x15' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*XPATH_B x8' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_MULT_B x6' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_SUB_B x2' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_SUB_B_C x1' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_MULT_B_C x12' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_MACC x2' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_SUB_MACC x1' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q 'modes inferred:.*PREADD_A_MACC_C x1' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && ! grep -q 'no cross-path control word for it with an ALU term' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && ! grep -q 'one signal on ports A and B' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && ! grep -q 'register chain given up' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q '2 x  the shared cross-path operand takes D, which holds one register stage' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_verify += && grep -q '4 x  reached the bank depth limit' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
# The overlap blocks' own wiring: the flip must put the overlapping slice (or
# the whole signal, ovlr) on D, not leave it on X. The pre-adder computes
# D +/- X: D has its own port, X comes from port A or port B. In the netlist,
# the pre-adder leaf's I0 is D and its I1 is X. test -s first, so a crash
# before write_verilog cannot pass on a stale file.
qlf_k6n10f-dspv4_xpath_verify += && test -s qlf_k6n10f/dspv4_xpath/netlist.v
qlf_k6n10f-dspv4_xpath_verify += && grep -A3 'QL_DSP4_PREADD ovl_d_QL_DSP4_PREADD_I1 ' qlf_k6n10f/dspv4_xpath/netlist.v | grep -q 'ovl_a\[15:0\] })'
qlf_k6n10f-dspv4_xpath_verify += && grep -A3 'QL_DSP4_PREADD ovlc_d_QL_DSP4_PREADD_I1 ' qlf_k6n10f/dspv4_xpath/netlist.v | grep -q 'ovlc_a\[15:0\] })'
qlf_k6n10f-dspv4_xpath_verify += && grep -A3 'QL_DSP4_PREADD ovlr_d_QL_DSP4_PREADD_I1 ' qlf_k6n10f/dspv4_xpath/netlist.v | grep -q 'ovlr_a })'
# ov2 and ov2r: the same two addends, written in opposite order, must land the
# same operand (the whole signal) off the X side in both cases. The instance
# name suffix comes from autoname and differs by Yosys version.
qlf_k6n10f-dspv4_xpath_verify += && grep -A3 'QL_DSP4_PREADD ov2_a_QL_DSP4_[A-Z0-9_]* ' qlf_k6n10f/dspv4_xpath/netlist.v | grep -q 'ov2_a\[7:0\] })'
qlf_k6n10f-dspv4_xpath_verify += && grep -A3 'QL_DSP4_PREADD ov2r_a_QL_DSP4_[A-Z0-9_]* ' qlf_k6n10f/dspv4_xpath/netlist.v | grep -q 'ov2r_a\[7:0\] })'
# Cross-path shapes the pass refuses, and the reason it prints for each: an
# ALU term with the shared operand left on X, no control word for the ALU
# direction, a sum that may exceed the multiplier port, a truncated sum, an
# unsigned subtract, and multiplies too wide for the ports. No block may print
# the one-signal-on-ports-A-and-B line: the pass does not refuse that wiring.
# mul2dsp splits the too-wide multiplies and the pass reads the pieces again,
# which prints the second "modes inferred" line. The x-grep rule fails if the
# written netlist holds a constant with x bits: that is what a net whose
# driver was lost becomes once `opt_clean` has run. `test -s` first, so a run
# that crashes before `write_verilog` cannot pass on a stale file.
qlf_k6n10f-dspv4_xpath_refused_verify = grep -E -q 'modes inferred: [^,]+(, [^,]+){5}$$' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred:.*MULT x2' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred:.*MULT_ADD_C x2' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred:.*MULT_SUB_C x1' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred:.*MULT_RSUB_C x1' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred:.*MULT_ACC_SUB x1' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred:.*MULT_ACC x1' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -E -q 'modes inferred: [^,]+(, [^,]+){1}$$' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'modes inferred: MULT x15, MULT_ADD_C x1' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '6 x  pre-adder: its sum may exceed the multiplier port' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '3 x  pre-adder: no cross-path control word for it with an ALU term' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '3 x  pre-adder: no control word for it with this ALU direction' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && ! grep -q 'one signal on ports A and B' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '2 x  pre-adder: an unsigned subtract wraps where the DSP signs' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '1 x  pre-adder: it truncates its own sum, which the DSP would not' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'multiply: 20x19 (signed x signed) does not fit the 32x18 ports' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q 'multiply: 33x16 (signed x signed) does not fit the 32x18 ports' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '19x18 (unsigned x unsigned) does not fit the 32x18 ports; an unsigned operand needs a spare bit' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '3 x  multiply: 32x16 (unsigned x unsigned) does not fit the 32x18 ports; an unsigned operand needs a spare bit' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && grep -q '18x20 (unsigned x unsigned) does not fit the 32x18 ports; an unsigned operand needs a spare bit' qlf_k6n10f/dspv4_xpath_refused/dspv4_xpath_refused.log
qlf_k6n10f-dspv4_xpath_refused_verify += && test -s qlf_k6n10f/dspv4_xpath_refused/netlist.v
qlf_k6n10f-dspv4_xpath_refused_verify += && ! grep -E -q "'[bh][0-9a-f]*x" qlf_k6n10f/dspv4_xpath_refused/netlist.v
# Three modes, each grepped on its own: the order of the line changes when
# two modes tie, and a count alone cannot say pipe, aa, pipe2, two_en, mulr,
# addr and cst each correctly kept PREADD_A_MULT_B rather than something
# else. cst's own wiring is asserted from the written
# netlist (test -s first, so a crash before write_verilog cannot pass on a
# stale file): a constant has no wire, so the cross-path test cannot treat
# it as the shared operand, and the word keeps the constant on both A and B.
# The two greps read the leaf cells' ports. The pre-adder's I1 is X, here
# port A (its I0 is port D). The multiplier's I0 is its 18-bit input, here
# port B (its I1 is the 32-bit input, here the pre-adder's sum).
qlf_k6n10f-dspv4_double_feed_scope_verify = grep -E -q 'modes inferred: [^,]+(, [^,]+){2}$$' qlf_k6n10f/dspv4_double_feed_scope/dspv4_double_feed_scope.log
qlf_k6n10f-dspv4_double_feed_scope_verify += && grep -q 'modes inferred:.*MULT_ADD_C x2' qlf_k6n10f/dspv4_double_feed_scope/dspv4_double_feed_scope.log
qlf_k6n10f-dspv4_double_feed_scope_verify += && grep -q 'modes inferred:.*PREADD_A_MULT_B x7' qlf_k6n10f/dspv4_double_feed_scope/dspv4_double_feed_scope.log
qlf_k6n10f-dspv4_double_feed_scope_verify += && grep -q 'modes inferred:.*MULT x1' qlf_k6n10f/dspv4_double_feed_scope/dspv4_double_feed_scope.log
qlf_k6n10f-dspv4_double_feed_scope_verify += && ! grep -q 'one signal on ports A and B' qlf_k6n10f/dspv4_double_feed_scope/dspv4_double_feed_scope.log
qlf_k6n10f-dspv4_double_feed_scope_verify += && test -s qlf_k6n10f/dspv4_double_feed_scope/netlist.v
qlf_k6n10f-dspv4_double_feed_scope_verify += && grep -A3 'QL_DSP4_PREADD ' qlf_k6n10f/dspv4_double_feed_scope/netlist.v | grep -q '\.I1(32.d12345)'
qlf_k6n10f-dspv4_double_feed_scope_verify += && grep -A3 'QL_DSP4_MULT ' qlf_k6n10f/dspv4_double_feed_scope/netlist.v | grep -q '\.I0(18.h03039)'
# Phase 4, register absorption into the pre-adder's D and AD banks. The mode
# has to be asserted here as well as the cell counts: a register absorbed into
# the wrong bank, or an operand register absorbed after the pre-adder was
# quietly dropped, still leaves one QL_DSP4_PREADD and no fabric flops.
# Four cells, one mode. The count alone cannot show the pre-adder survived in
# all four, and the P-bank count in the .tcl cannot show which way it went.
qlf_k6n10f-dspv4_preadd_preg_wrap_verify = grep -q 'modes inferred: PREADD_A_MULT_B x4' qlf_k6n10f/dspv4_preadd_preg_wrap/dspv4_preadd_preg_wrap.log
# Resettable AD registers fold: four PREADD words. MULT would mean refused.
qlf_k6n10f-dspv4_preadd_adreg_rst_verify = grep -q 'modes inferred: PREADD_A_MULT_B x4' qlf_k6n10f/dspv4_preadd_adreg_rst/dspv4_preadd_adreg_rst.log
# The pre-adder survives: the cell gave up a register chain instead of
# giving up the fold. MULT would mean we refused. The summary names each
# chain it gave up, one per cell, and cr's result register with its reason.
# Every AD register here ends in an AD bank, so no line may say otherwise:
# that line used to come from the refused offer that lost.
qlf_k6n10f-dspv4_preadd_adreg_evict_verify = grep -q 'modes inferred: PREADD_A_MULT_B x6' qlf_k6n10f/dspv4_preadd_adreg_evict/dspv4_preadd_adreg_evict.log
qlf_k6n10f-dspv4_preadd_adreg_evict_verify += && grep -q '5 x  B register chain given up: it resets differently from the AD register, and both take RSTN' qlf_k6n10f/dspv4_preadd_adreg_evict/dspv4_preadd_adreg_evict.log
qlf_k6n10f-dspv4_preadd_adreg_evict_verify += && grep -q '1 x  the cell took a pre-adder output register instead' qlf_k6n10f/dspv4_preadd_adreg_evict/dspv4_preadd_adreg_evict.log
# cn's result register has a blocker of its own, its reset value; that is
# the line it gets, and cr stays the only one that the cell took AD instead.
qlf_k6n10f-dspv4_preadd_adreg_evict_verify += && grep -q '1 x  it resets to a non-zero value, and the P bank resets to zero' qlf_k6n10f/dspv4_preadd_adreg_evict/dspv4_preadd_adreg_evict.log
qlf_k6n10f-dspv4_preadd_adreg_evict_verify += && ! grep -q 'cannot go in the AD bank' qlf_k6n10f/dspv4_preadd_adreg_evict/dspv4_preadd_adreg_evict.log

# Every cell a refusal leaves in fabric is named, once, with its reason --
# counted after the run, so a cell a later offer absorbed is never named.
qlf_k6n10f-dspv4_mult_keep_verify = grep -q '1 x  adder: the product it reads is marked keep' qlf_k6n10f/dspv4_mult_keep/dspv4_mult_keep.log
qlf_k6n10f-dspv4_mult_wide_verify = grep -q '1 x  multiply: its 80-bit result exceeds the 50-bit P port' qlf_k6n10f/dspv4_mult_wide/dspv4_mult_wide.log
qlf_k6n10f-dspv4_mult_wide_regin_verify = grep -q '1 x  multiply: its 64-bit result exceeds the 50-bit P port' qlf_k6n10f/dspv4_mult_wide_regin/dspv4_mult_wide_regin.log
qlf_k6n10f-dspv4_mult_wide_result_verify = grep -q '1 x  adder: its 64-bit result exceeds the 50-bit P port' qlf_k6n10f/dspv4_mult_wide_result/dspv4_mult_wide_result.log
qlf_k6n10f-dspv4_trunc_verify = grep -q '1 x  adder: the RTL cuts the product to 17 bits and reads above the cut' qlf_k6n10f/dspv4_trunc/dspv4_trunc.log
# The accumulator over a cut product: its register is not on any DSP result,
# so it must not be called "not offered" -- that line came from a losing offer.
qlf_k6n10f-dspv4_trunc_verify += && ! grep -q 'the pattern did not offer it' qlf_k6n10f/dspv4_trunc/dspv4_trunc.log
# -chain_max 0 and 1 are off: the option is accepted, the netlist is the one the
# pass gives with no option, and there is no chain report. The fold is counted,
# once per log, because the flow calls the pass twice.
casc_flags_dir = qlf_k6n10f/dspv4_casc_flags
qlf_k6n10f-dspv4_casc_flags_verify = true
qlf_k6n10f-dspv4_casc_flags_verify += $(foreach b,_off_ref _off _n1,&& test "$$(grep -c 'modes inferred: MULT_ADD_C x4$$' $(casc_flags_dir)/$(b).log)" = 1)
qlf_k6n10f-dspv4_casc_flags_verify += $(foreach b,_off_ref _off _n1,&& ! grep -q 'ql_dspv4: cascade' $(casc_flags_dir)/$(b).log)
qlf_k6n10f-dspv4_casc_flags_verify += && cmp $(casc_flags_dir)/_off_ref.blif $(casc_flags_dir)/_off.blif
qlf_k6n10f-dspv4_casc_flags_verify += && cmp $(casc_flags_dir)/_off.blif $(casc_flags_dir)/_n1.blif
# One source, two consumers, twice: the same netlist both times.
qlf_k6n10f-dspv4_casc_flags_verify += $(foreach r,run1 run2,&& test "$$(grep -c 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_flags_dir)/_fanout_det_$(r).log)" = 1)
qlf_k6n10f-dspv4_casc_flags_verify += && cmp $(casc_flags_dir)/_fanout_det_run1.blif $(casc_flags_dir)/_fanout_det_run2.blif
# A chain longer than N = 4 is cut after every fourth cell.
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD x3, MULT_ADD_C x2$$' $(casc_flags_dir)/_too_long.log
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_found,$(casc_flags_dir)/_too_long.log,4,1)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_reason,$(casc_flags_dir)/_too_long.log,$(casc_too_long),1)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_wired,$(casc_flags_dir)/_too_long.log,3,2)
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD x6, MULT_ADD_C x3$$' $(casc_flags_dir)/_too_long_2.log
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_found,$(casc_flags_dir)/_too_long_2.log,8,2)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_reason,$(casc_flags_dir)/_too_long_2.log,$(casc_too_long),2)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_wired,$(casc_flags_dir)/_too_long_2.log,6,3)
# The chain report in the flags blocks.
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_reset_call1.log,3,1,4,12)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_fanout_det_run1.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_fanout_det_run2.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_too_long.log,3,1,4,4)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_too_long_2.log,6,2,4,4)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_ranked,$(casc_flags_dir)/_too_long_2.log,2,$(casc_too_long))
# The option does not carry over to the next pass call: the first call links
# three stages, the second links none.
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD x3, MULT_ADD_C x1$$' $(casc_flags_dir)/_reset_call1.log
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD_C x4$$' $(casc_flags_dir)/_reset_call2.log
# The declined addend groupings do not carry over either: the first call
# declines one, the second folds its $add and lists nothing.
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD x1, MULT x1$$' $(casc_flags_dir)/_declined_reset_call1.log
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_declined_reset_call1.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_declined,$(casc_flags_dir)/_declined_reset_call1.log,1,addend sum wire is too narrow)
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT x1$$' $(casc_flags_dir)/_declined_reset_call2.log
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_declined_reset_call2.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_no_declined,$(casc_flags_dir)/_declined_reset_call2.log)
# -chain_max 3 still runs the cascade step: three stages are linked, in one chain.
qlf_k6n10f-dspv4_casc_flags_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x2$$' $(casc_flags_dir)/_n3.log
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_report,$(casc_flags_dir)/_n3.log,2,1,3,3)

# A -chain_max value that is not a plain non-negative integer is refused by both
# synth_ql and ql_dspv4: the call fails (refused.log has 12 REFUSED lines and no
# ACCEPTED one) and the error line naming the value is in the log twice.
casc_bad_dir = qlf_k6n10f/dspv4_casc_chain_max_refused
casc_bad_message = test "$$(grep -Fxc -e "ERROR: -chain_max expects a non-negative integer, got '$(1)'." $(casc_bad_dir)/dspv4_casc_chain_max_refused.log)" = 2
qlf_k6n10f-dspv4_casc_chain_max_refused_verify = test "$$(grep -c '^REFUSED ' $(casc_bad_dir)/refused.log)" = 12
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && ! grep -q '^ACCEPTED ' $(casc_bad_dir)/refused.log
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && $(call casc_bad_message,twelve)
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && $(call casc_bad_message,-4)
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && $(call casc_bad_message,12abc)
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && $(call casc_bad_message,)
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && $(call casc_bad_message,1 2)
qlf_k6n10f-dspv4_casc_chain_max_refused_verify += && $(call casc_bad_message,99999999999)

# -chain_max that cannot apply is reported by synth_ql, once, naming the reason.
# With -dspv4 and DSPs mapped it applies and nothing is reported.
casc_ignored = test "$$(grep -c 'Warning: -chain_max is ignored: $(2)' $(casc_flags_dir)/_ignored_$(1).log)" = 1
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_ignored,no_dspv4,it applies only with -dspv4[.])
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_ignored,synplify,ql_dspv4 does not run with -synplify[.])
qlf_k6n10f-dspv4_casc_flags_verify += && $(call casc_ignored,no_dsp,ql_dspv4 does not run with -no_dsp[.])
qlf_k6n10f-dspv4_casc_flags_verify += && ! grep -q 'chain_max is ignored' $(casc_flags_dir)/_applied.log
# What the finder makes of each block: how many candidate links, and how many
# reads it refuses itself. casc_found takes the block's log and the two counts.
casc_found = test "$$(grep -c 'cascade candidate:' $(1))" = $(2) && test "$$(grep -c 'cascade link refused:' $(1))" = $(3)
# How a block's cells are wired, from the dump in its log: casc_wired takes the
# log, the number of cells that read PCIN and the number that read C. Every
# PCIN has a PCOUT, on the same wire.
casc_port = grep 'connect .$(2) ' $(1) | awk '{print $$3}' | sort
casc_wired = test "$$($(call casc_port,$(1),PCIN) | wc -l)" = $(2) && test "$$($(call casc_port,$(1),PCIN))" = "$$($(call casc_port,$(1),PCOUT))" && test "$$($(call casc_port,$(1),C) | wc -l)" = $(3)
# A chain the user instantiated is not the pass's to link: no cell inferred,
# no chain report, and the second cell still reads the first on C.
casc_links_dir = qlf_k6n10f/dspv4_casc_links
qlf_k6n10f-dspv4_casc_links_verify = grep -q 'inferred 0 QL_DSP4 cell(s)' $(casc_links_dir)/_macro_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'ql_dspv4: cascade' $(casc_links_dir)/_macro_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'modes inferred' $(casc_links_dir)/_macro_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q -F 'connect \C { \head_p [35]' $(casc_links_dir)/_macro_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_macro_cells.log,0,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_macro_cells.log,0,1)
# A chain the pass made: every stage after the first reads PCIN, in mode
# MULT_ADD. The mode line is counted, once, in the whole flow's log.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD x1, MULT x1$$' $(casc_links_dir)/_two.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x1, MULT x1$$' $(casc_links_dir)/_two_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_two_cells.log,1,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_two_cells.log,1,0)
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD x4, MULT x1$$' $(casc_links_dir)/_chain.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x4, MULT x1$$' $(casc_links_dir)/_chain_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_chain_cells.log,4,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_chain_cells.log,4,0)
# 50-bit sums of 32 x 18 products: the 50-bit port is the most any link asks.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD x2, MULT_ADD_C x1$$' $(casc_links_dir)/_wide_chain.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1$$' $(casc_links_dir)/_wide_chain_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_wide_chain_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_wide_chain_cells.log,2,1)
# A sum too narrow for its range still links when the next stage keeps no more
# bits than it reads.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD x2, MULT x1$$' $(casc_links_dir)/_trunc.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT x1$$' $(casc_links_dir)/_trunc_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_trunc_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_trunc_cells.log,2,0)
# A registered link: step 0 moves the register into the source when the matcher
# left it in the consumer. When the matcher put it in the source, step 0 is silent.
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT x1$$' $(casc_links_dir)/_reglink_preg_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_preg_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_preg_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'cascade: register into' $(casc_links_dir)/_reglink_preg_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT x1$$' $(casc_links_dir)/_reglink_move_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_move_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_move_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_move_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_move_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT x1$$' $(casc_links_dir)/_reglink_move_en_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_move_en_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_move_en_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_move_en_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_move_en_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT x1$$' $(casc_links_dir)/_reglink_matcher_copy_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_matcher_copy_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_matcher_copy_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_matcher_copy_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_matcher_copy_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'cascade: fabric copy .* of the link register removed$$' $(casc_links_dir)/_reglink_matcher_copy_cells.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: PREADD_A_MULT_B x1, MULT_ADD x1$$' $(casc_links_dir)/_reglink_enables_ok_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_enables_ok_cells.log,1,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_enables_ok_cells.log,1,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_enables_ok_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_enables_ok_cells.log
# One source, two consumers: rule 3 keeps one link.
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_links_dir)/_fanout_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_fanout_cells.log,2,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_reason,$(casc_links_dir)/_fanout_cells.log,$(casc_shorter),1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_fanout_cells.log,1,2)
# Of two equal consumers, the one whose name sorts first takes the link.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$($(call casc_cells,$(casc_links_dir)/_fanout_cells.log) | awk '$$3 == 0' | LC_ALL=C sort | head -1 | awk '{print $$2}')" = 1
# The longer chain takes the link: its first consumer reads PCIN and drives PCOUT.
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x2$$' $(casc_links_dir)/_fanout_longest_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_fanout_longest_cells.log,3,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_reason,$(casc_links_dir)/_fanout_longest_cells.log,$(casc_shorter),1)
qlf_k6n10f-dspv4_casc_links_verify += && test "$$($(call casc_cells,$(casc_links_dir)/_fanout_longest_cells.log) | awk '$$2 + $$3 == 2' | wc -l)" = 1
# The longer chain's link is registered and its register cannot move: rule 1
# refuses that link before rule 3 picks, so the source links to the other stage.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x2, MULT_ADD x2$$' $(casc_links_dir)/_fanout_filtered.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x2$$' $(casc_links_dir)/_fanout_filtered_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_fanout_filtered_cells.log,3,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_reason,$(casc_links_dir)/_fanout_filtered_cells.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_not_moved,$(casc_links_dir)/_fanout_filtered_cells.log,$(casc_other_reader),1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_fanout_filtered_cells.log,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_fanout_filtered_cells.log,2,2)
qlf_k6n10f-dspv4_casc_links_verify += $(foreach l,_fanout_filtered _fanout_filtered_cells,&& $(call casc_report,$(casc_links_dir)/$(l).log,2,2,2,12))
qlf_k6n10f-dspv4_casc_links_verify += $(foreach l,_fanout_filtered _fanout_filtered_cells,&& grep -q '^ql_dspv4: link registers not moved:$$' $(casc_links_dir)/$(l).log)
qlf_k6n10f-dspv4_casc_links_verify += $(foreach l,_fanout_filtered _fanout_filtered_cells,&& $(call casc_ranked,$(casc_links_dir)/$(l).log,1,$(casc_other_reader)))
qlf_k6n10f-dspv4_casc_links_verify += $(foreach l,_fanout_filtered _fanout_filtered_cells,&& $(call casc_ranked,$(casc_links_dir)/$(l).log,1,$(casc_registered)))
qlf_k6n10f-dspv4_casc_links_verify += $(foreach l,_fanout_filtered _fanout_filtered_cells,&& ! grep -q '$(casc_shorter)' $(casc_links_dir)/$(l).log)
qlf_k6n10f-dspv4_casc_links_verify += $(foreach l,_fanout_filtered _fanout_filtered_cells,&& ! grep -q 'link register(s) moved' $(casc_links_dir)/$(l).log)
# The head's P keeps its port; PCOUT is a wire of its own.
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_links_dir)/_head_fanout_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_head_fanout_cells.log,1,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_head_fanout_cells.log,1,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep 'connect .P ' $(casc_links_dir)/_head_fanout_cells.log | grep -qF "$$(grep 'connect .PCOUT ' $(casc_links_dir)/_head_fanout_cells.log | awk '{print $$3}')"
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1$$' $(casc_links_dir)/_mreg_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_mreg_cells.log,2,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_mreg_cells.log,2,1)
# Two consumers register one sum alike: one register moves, rule 3 keeps one link.
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1, MULT x1$$' $(casc_links_dir)/_reglink_two_consumers_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_two_consumers_cells.log,3,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_reason,$(casc_links_dir)/_reglink_two_consumers_cells.log,$(casc_shorter),1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_two_consumers_cells.log,2,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_two_consumers_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_two_consumers_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1, MULT x1$$' $(casc_links_dir)/_reglink_two_consumers_neg_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,3,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_reason,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,$(casc_shorter),1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,2,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_two_consumers_neg_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1, MULT x1$$' $(casc_links_dir)/_reglink_two_consumers_rst_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,3,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_reason,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,$(casc_shorter),1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,2,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'not moved' $(casc_links_dir)/_reglink_two_consumers_rst_cells.log
# The chain report, once per call that made a cell at N of 2 or more.
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_two_cells.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_chain_cells.log,4,1,5,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_wide_chain_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_trunc_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_move_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_move_en_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_matcher_copy_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_preg_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_fanout_cells.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_fanout_longest_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_head_fanout_cells.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_mreg_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_two_consumers_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,2,1,3,12)
# Once in a whole flow: the second pass call makes no cell and prints nothing.
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_two.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_chain.log,4,1,5,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_wide_chain.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_trunc.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved_report,$(casc_links_dir)/_reglink_move_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved_report,$(casc_links_dir)/_reglink_two_consumers_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_ranked,$(casc_links_dir)/_fanout_cells.log,1,$(casc_shorter))
# Step 0's report lines and the refused list, as each block's row gives them.
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved_report,$(casc_links_dir)/_reglink_move_en_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved_report,$(casc_links_dir)/_reglink_matcher_copy_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved_report,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_moved_report,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,1)
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'link register' $(casc_links_dir)/_reglink_preg_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_ranked,$(casc_links_dir)/_reglink_two_consumers_cells.log,1,$(casc_shorter))
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_ranked,$(casc_links_dir)/_reglink_two_consumers_neg_cells.log,1,$(casc_shorter))
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_ranked,$(casc_links_dir)/_reglink_two_consumers_rst_cells.log,1,$(casc_shorter))
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_ranked,$(casc_links_dir)/_fanout_longest_cells.log,1,$(casc_shorter))
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'cascade links refused' $(casc_links_dir)/_trunc.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'cascade links refused' $(casc_links_dir)/_trunc_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'cascade links refused' $(casc_links_dir)/_reglink_matcher_copy_cells.log
# _fanout through the whole flow: the fold, the report and its list, once.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_links_dir)/_fanout.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_fanout.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_ranked,$(casc_links_dir)/_fanout.log,1,$(casc_shorter))
# Two chains of four cells and two: the report's longest is the larger, 4.
qlf_k6n10f-dspv4_casc_links_verify += && test "$$(grep -c 'modes inferred: MULT_ADD x4, MULT x2$$' $(casc_links_dir)/_chains_unequal.log)" = 1
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_chains_unequal.log,4,2,4,12)
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD x4, MULT x2$$' $(casc_links_dir)/_chains_unequal_cells.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_chains_unequal_cells.log,4,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_wired,$(casc_links_dir)/_chains_unequal_cells.log,4,0)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_report,$(casc_links_dir)/_chains_unequal_cells.log,4,2,4,12)
casc_refused_dir = qlf_k6n10f/dspv4_casc_refused
$(casc_refused_dir)/ok: $(wildcard $(casc_refused_dir)/*.v)
casc_read_unsigned = cascade link refused: .*: link is read unsigned, and PCIN sign-extends$$
# How many of a block's refused links carry this reason: the log, the reason,
# the count. Double quotes, because a reason can hold an apostrophe.
casc_reason = test "$$(grep -c "cascade link refused: .*: $(2)$$" $(1))" = $(3)
casc_registered = consumer registered the link (CREG), and PCIN has no register
casc_too_narrow = RTL sum is too narrow for the source's P range
# Step 0's -verbose lines: how many registers moved, and how many sources kept
# theirs for this reason.
casc_moved = test "$$(grep -c 'cascade: register into .* moved$$' $(1))" = $(2)
casc_not_moved = test "$$(grep -c "cascade: register into .* not moved: $(2)$$" $(1))" = $(3)
casc_other_reader = the source's P has another reader
casc_has_preg = the source already has a P register
casc_other_clock = the source is on another clock
casc_enables = the source would need more than 3 distinct clock enables
casc_differently = the source's readers register it differently (different CLK, CEC, or RSTN)
casc_kept_sum = the source's P is marked keep
casc_loop = links form a loop
casc_shorter = source already feeds a chain at least as long
casc_too_long = chain would exceed the device limit
casc_unsigned = link is read unsigned, and PCIN sign-extends
# The chain report: its count line, once, with the links, the chains, the cells
# in the longest chain and the limit; and one line of one of its lists.
casc_report = test "$$(grep -c '^ql_dspv4: cascade: [0-9]* PCIN link' $(1))" = 1 && grep -q '^ql_dspv4: cascade: $(2) PCIN link(s) in $(3) chain(s), longest $(4) (limit $(5))$$' $(1)
casc_ranked = grep -q "^ *$(2) x  $(3)$$" $(1)
# Step 0's report line, once, with the number of registers moved.
casc_moved_report = test "$$(grep -c '^ql_dspv4: cascade: [0-9]* link register(s) moved' $(1))" = 1 && grep -q "^ql_dspv4: cascade: $(2) link register(s) moved to the source's PREG$$" $(1)
# Each QL_DSP4 cell of a dump: its name, whether it reads PCIN, whether it drives PCOUT.
casc_cells = awk '/^  cell /{if(n!="")print n, i, o; n=$$3; i=o=0} /connect .PCIN /{i=1} /connect .PCOUT /{o=1} END{if(n!="")print n, i, o}' $(1)
# The OPMODE of the QL_DSP4 cell whose name sorts first as text, from the dump.
casc_first_opmode = awk '/^  cell .QL_DSP4/{n=$$3} /parameter .OPMODE /{print n, $$3}' $(1) | LC_ALL=C sort | awk 'NR==1{print $$2}'
qlf_k6n10f-dspv4_casc_refused_verify = grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink.log,$(casc_other_reader),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink.log,0)
# A link register that step 0 cannot move, one block per check. Rule 1 then
# refuses the link for its CREG.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink_two_regs.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_two_regs.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_two_regs.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_two_regs.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_two_regs.log,$(casc_has_preg),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_two_regs.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink_clock.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_clock.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_clock.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_clock.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_clock.log,$(casc_other_clock),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_clock.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink_kept_sum.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_kept_sum.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_kept_sum.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_kept_sum.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_kept_sum.log,$(casc_kept_sum),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_kept_sum.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink_two_consumers_diff.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_two_consumers_diff.log,3,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_two_consumers_diff.log,$(casc_registered),2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_two_consumers_diff.log,1,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_two_consumers_diff.log,$(casc_differently),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_two_consumers_diff.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink_two_consumers_neg_diff.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,3,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,$(casc_registered),2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,1,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,$(casc_differently),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT x1$$' $(casc_refused_dir)/_reglink_copy_diff_en.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_copy_diff_en.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_copy_diff_en.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_copy_diff_en.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_copy_diff_en.log,$(casc_other_reader),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_copy_diff_en.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_A_MULT_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_reglink_enables.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_reglink_enables.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_reglink_enables.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_reglink_enables.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_not_moved,$(casc_refused_dir)/_reglink_enables.log,$(casc_enables),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_reglink_enables.log,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_unsigned.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_unsigned.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '$(casc_read_unsigned)' $(casc_refused_dir)/_unsigned.log
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT x1$$' $(casc_refused_dir)/_pad.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_pad.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '$(casc_read_unsigned)' $(casc_refused_dir)/_pad.log
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_slice.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_slice.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT x2, MULT_ADD_C x1$$' $(casc_refused_dir)/_multicell.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_multicell.log,0,0)
# Too narrow: the sum cannot hold the source's P range, and the next stage
# keeps more bits than it reads.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1, MULT x1$$' $(casc_refused_dir)/_chain_tight.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_chain_tight.log,3,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_chain_tight.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_chain_tight.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_head_addend.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_head_addend.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_head_addend.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_head_addend.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT_ACC_C x1$$' $(casc_refused_dir)/_full_port_chain.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_full_port_chain.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_full_port_chain.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_full_port_chain.log,1,2)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x3, MULT_ADD x1$$' $(casc_refused_dir)/_width_reset.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_width_reset.log,3,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_width_reset.log,$(casc_too_narrow),2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_width_reset.log,1,3)
# The same refusal from a subtracting, a B-path pre-adder and a cross-path source.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_SUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_sub_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_sub_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_sub_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_sub_source.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_B_MULT_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_b_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_b_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_b_source.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: XPATH_A x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_xpath_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_xpath_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_xpath_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_xpath_source.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ACC x1$$' $(casc_refused_dir)/_acc_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_acc_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_acc_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_acc_source.log,0,1)
# A loop loses one registered link, the one into the cell first in name order.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_refused_dir)/_loop.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_loop.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_loop.log,$(casc_loop),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_loop.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved,$(casc_refused_dir)/_loop.log,1)
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'not moved' $(casc_refused_dir)/_loop.log
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$($(call casc_first_opmode,$(casc_refused_dir)/_loop.log))" = "9'000110101"
# A loop no rule 1 check touches: the link into the cell with PREG is dropped.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_refused_dir)/_loop_acc.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_loop_acc.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_loop_acc.log,$(casc_loop),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_loop_acc.log,1,1)
# After the drop, the width walk runs from the new head, and out of the loop.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_refused_dir)/_loop_head_walk.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_loop_head_walk.log,3,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_loop_head_walk.log,$(casc_loop),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_loop_head_walk.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_loop_head_walk.log,1,2)
# The chain report, once per call that made a cell; the finder's refusals are in its list.
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_reglink.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_reglink_two_regs.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_reglink_clock.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_reglink_two_consumers_diff.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_reglink_copy_diff_en.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_unsigned.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_pad.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_slice.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_multicell.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_chain_tight.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_head_addend.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_full_port_chain.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_width_reset.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_sub_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_xpath_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_loop.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_sub.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_acc_tail.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_acc_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_loop_head_walk.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_loop_acc.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: cascade links refused:$$' $(casc_refused_dir)/_unsigned.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_unsigned.log,1,$(casc_unsigned))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_chain_tight.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_width_reset.log,2,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: link registers not moved:$$' $(casc_refused_dir)/_reglink.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink.log,1,$(casc_other_reader))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink.log,1,$(casc_registered))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_two_consumers_diff.log,2,$(casc_differently))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_two_consumers_diff.log,2,$(casc_registered))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_loop.log,1,$(casc_loop))
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'link registers not moved' $(casc_refused_dir)/_loop.log
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_slice.log
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_multicell.log
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_sub.log
# Step 0's two lists on every block whose register stays, and no moved line.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: link registers not moved:$$' $(casc_refused_dir)/_reglink_two_regs.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_two_regs.log,1,$(casc_has_preg))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_two_regs.log,1,$(casc_registered))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: link registers not moved:$$' $(casc_refused_dir)/_reglink_clock.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_clock.log,1,$(casc_other_clock))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_clock.log,1,$(casc_registered))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: link registers not moved:$$' $(casc_refused_dir)/_reglink_two_consumers_neg_diff.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,2,$(casc_differently))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_two_consumers_neg_diff.log,2,$(casc_registered))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: link registers not moved:$$' $(casc_refused_dir)/_reglink_copy_diff_en.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_copy_diff_en.log,1,$(casc_other_reader))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_reglink_copy_diff_en.log,1,$(casc_registered))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: link registers not moved:$$' $(casc_refused_dir)/_reglink_two_consumers_diff.log
qlf_k6n10f-dspv4_casc_refused_verify += $(foreach b,_reglink _reglink_two_regs _reglink_clock _reglink_two_consumers_diff _reglink_two_consumers_neg_diff _reglink_copy_diff_en,&& ! grep -q 'link register(s) moved' $(casc_refused_dir)/$(b).log)
# The loops' lists.
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_moved_report,$(casc_refused_dir)/_loop.log,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_loop_head_walk.log,1,$(casc_loop))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_loop_head_walk.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_loop_acc.log,1,$(casc_loop))
# The width and finder reasons in the refused list.
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_head_addend.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_full_port_chain.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_acc_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_sub_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_xpath_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '^ql_dspv4: cascade links refused:$$' $(casc_refused_dir)/_pad.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_pad.log,1,$(casc_unsigned))
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_acc_tail.log
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_preadd_b.log
# The whole flow on the blocks that read no cell: the fold and the report once
# each, and the same refused list.
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_unsigned_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_unsigned_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_unsigned_flow.log,1,$(casc_unsigned))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x1, MULT x1$$' $(casc_refused_dir)/_pad_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_pad_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_pad_flow.log,1,$(casc_unsigned))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_slice_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_slice_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_slice_flow.log
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT x2, MULT_ADD_C x1$$' $(casc_refused_dir)/_multicell_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_multicell_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_multicell_flow.log
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD x2, MULT_ADD_C x1, MULT x1$$' $(casc_refused_dir)/_chain_tight_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_chain_tight_flow.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_chain_tight_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_head_addend_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_head_addend_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_head_addend_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT_ACC_C x1$$' $(casc_refused_dir)/_full_port_chain_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_full_port_chain_flow.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_full_port_chain_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x3, MULT_ADD x1$$' $(casc_refused_dir)/_width_reset_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_width_reset_flow.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_width_reset_flow.log,2,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_SUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_sub_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_sub_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_sub_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_B_MULT_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: XPATH_A x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_xpath_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_xpath_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_xpath_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_SUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_sub_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_sub_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_sub_flow.log
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x1, MULT_ACC_C x1$$' $(casc_refused_dir)/_acc_tail_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_acc_tail_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_acc_tail_flow.log
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_B_MULT_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_preadd_b_flow.log
# The remaining P range rows: each source's one link refused as too narrow,
# on the stopped run and in the whole flow.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_RSUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_rsub_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_rsub_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_rsub_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_rsub_source.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_rsub_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_rsub_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_RSUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_rsub_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_rsub_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_rsub_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_A_SUB_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_sub_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_a_sub_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_a_sub_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_a_sub_source.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_sub_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_sub_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_A_SUB_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_sub_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_sub_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_sub_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_A_SUB_B_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_sub_c_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_a_sub_c_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_a_sub_c_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_a_sub_c_source.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_sub_c_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_sub_c_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_A_SUB_B_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_sub_c_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_sub_c_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_sub_c_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_B_MULT_A x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_mult_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_b_mult_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_b_mult_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_b_mult_source.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_mult_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_mult_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_B_MULT_A x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_mult_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_mult_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_mult_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_B_SUB_A x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_sub_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_b_sub_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_b_sub_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_b_sub_source.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_sub_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_sub_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_B_SUB_A x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_sub_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_sub_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_sub_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_B_SUB_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_sub_c_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_b_sub_c_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_b_sub_c_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_b_sub_c_source.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_sub_c_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_sub_c_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_B_SUB_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b_sub_c_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_b_sub_c_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_b_sub_c_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: XPATH_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_xpath_b_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_xpath_b_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_xpath_b_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_xpath_b_source.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_xpath_b_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_xpath_b_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: XPATH_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_xpath_b_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_xpath_b_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_xpath_b_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_A_MULT_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_mult_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_a_mult_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_a_mult_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_a_mult_source.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_mult_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_mult_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_A_MULT_B x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_mult_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_mult_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_mult_source_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_A_MULT_B_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_mult_c_source.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_a_mult_c_source.log,1,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_preadd_a_mult_c_source.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_preadd_a_mult_c_source.log,0,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_mult_c_source.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_mult_c_source.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: PREADD_A_MULT_B_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_a_mult_c_source_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_preadd_a_mult_c_source_flow.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_preadd_a_mult_c_source_flow.log,1,$(casc_too_narrow))
# A fan-out source whose narrow link the width rule refuses: one link, one
# refusal, and no rule 3 refusal.
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_refused_dir)/_fanout_narrow.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_fanout_narrow.log,2,1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_fanout_narrow.log,$(casc_too_narrow),1)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_reason,$(casc_refused_dir)/_fanout_narrow.log,$(casc_shorter),0)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_wired,$(casc_refused_dir)/_fanout_narrow.log,1,2)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_fanout_narrow.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_fanout_narrow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && test "$$(grep -c 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_refused_dir)/_fanout_narrow_flow.log)" = 1
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_report,$(casc_refused_dir)/_fanout_narrow_flow.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_ranked,$(casc_refused_dir)/_fanout_narrow_flow.log,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q '$(casc_shorter)' $(casc_refused_dir)/_fanout_narrow_flow.log
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_acc_tail.log
qlf_k6n10f-dspv4_casc_refused_verify += && ! grep -q 'cascade links refused' $(casc_refused_dir)/_preadd_b.log
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_SUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_sub.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_sub.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ACC_C x1$$' $(casc_refused_dir)/_acc_tail.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_acc_tail.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_B_MULT_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_b.log,0,0)
# A per-stage addend. The groupings declined, a list -verbose prints after the
# refused one: the log and its one entry, or no such list at all.
casc_declined_list = awk '/^ql_dspv4: addend groupings declined:$$/{on=1; next} /^ql_dspv4: /{on=0} /^ +[0-9]+ x  /{if (on) print}' $(1) | sed 's/^ *//'
casc_declined = test "$$($(call casc_declined_list,$(1)))" = '$(2) x  $(3)'
casc_no_declined = ! grep -q 'addend groupings declined' $(1)
casc_other_adder_reader = addend adder has another reader
casc_addend_unsigned = link is read unsigned in addend grouping
casc_addend_narrow = addend sum wire is too narrow
casc_addend_wide = addend result is wider than the P port
casc_addend_registered = consumer registered the sum (PREG), and C is added before the register
casc_addend_kept = addend sum wire is marked keep
# The OPMODE of each cell that reads PCIN, in text order of the cell's name.
casc_consumer_opmodes = awk '/^  cell /{if(n!="")print n, i, o; n=$$3; i=0} /connect .PCIN /{i=1} /parameter .OPMODE /{o=$$3} END{if(n!="")print n, i, o}' $(1) | awk '$$2 == 1' | LC_ALL=C sort | awk '{printf "%s ", $$3}'
casc_addend_dir = qlf_k6n10f/dspv4_casc_addend
# Grouping 2: every $add goes and every consumer takes MULT_ADD_C_CASC.
qlf_k6n10f-dspv4_casc_addend_verify = grep -q 'modes inferred: MULT_ADD_C_CASC x2, MULT_ADD_C x1$$' $(casc_addend_dir)/_addend.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend.log,2,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend.log,2,3)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT_ADD_C x1$$' $(casc_addend_dir)/_addend_g2_swapped.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_g2_swapped.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_g2_swapped.log,1,2)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_g2_swapped.log,1,1,2,12)
# Grouping 1 written left to right: the tail's $add stays, the others go as grouping 2.
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x2, MULT_ADD_C x1, MULT_ADD x1$$' $(casc_addend_dir)/_addend_grouped.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_grouped.log,3,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_grouped.log,3,3)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_grouped.log,3,1,4,12)
qlf_k6n10f-dspv4_casc_addend_verify += && test "$$(grep -c 'grouping 1 skipped' $(casc_addend_dir)/_addend_grouped.log)" = 1
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT_ADD_C x1$$' $(casc_addend_dir)/_addend_creg.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_creg.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_creg.log,1,2)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_creg.log,1,1,2,12)
# One $add in both groupings: grouping 2 takes it, and the skip is not counted.
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT_ADD x1, MULT x1$$' $(casc_addend_dir)/_addend_both.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_both.log,2,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_both.log,2,1)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_both.log,2,1,3,12)
qlf_k6n10f-dspv4_casc_addend_verify += && test "$$(grep -c 'grouping 1 skipped' $(casc_addend_dir)/_addend_both.log)" = 1
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_no_declined,$(casc_addend_dir)/_addend_both.log)
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT x1$$' $(casc_addend_dir)/_double_prev.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_double_prev.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_double_prev.log,1,1)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_double_prev.log,1,1,2,12)
# A $add that does not read the whole result from bit 0 is no grouping 1, and
# is not counted.
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach b,_addend_g1_shifted _addend_g1_in_zero_pad,&& grep -q 'modes inferred: MULT_ADD x1, MULT x1$$' $(casc_addend_dir)/$(b).log)
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach b,_addend_g1_shifted _addend_g1_in_zero_pad,&& $(call casc_found,$(casc_addend_dir)/$(b).log,1,0))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach b,_addend_g1_shifted _addend_g1_in_zero_pad,&& $(call casc_report,$(casc_addend_dir)/$(b).log,1,1,2,12))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach b,_addend_g1_shifted _addend_g1_in_zero_pad,&& test "$$(grep -c 'not grouping 1' $(casc_addend_dir)/$(b).log)" = 1)
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach b,_addend_g1_shifted _addend_g1_in_zero_pad,&& $(call casc_no_declined,$(casc_addend_dir)/$(b).log))
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT x1$$' $(casc_addend_dir)/_addend_g1_cap.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_g1_cap.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_g1_cap.log,1,1)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_g1_cap.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_no_declined,$(casc_addend_dir)/_addend_g1_cap.log)
# Two cells' results on one $add: the consumer first in name order takes it,
# in both line orders. The same RTL through the whole flow gives one BLIF.
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2 run3,&& grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD_C_CASC x1, MULT_ADD x1$$' $(casc_addend_dir)/_addend_g1_tie_$(r).log)
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2 run3,&& $(call casc_found,$(casc_addend_dir)/_addend_g1_tie_$(r).log,2,0))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2 run3,&& $(call casc_wired,$(casc_addend_dir)/_addend_g1_tie_$(r).log,2,3))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2 run3,&& $(call casc_report,$(casc_addend_dir)/_addend_g1_tie_$(r).log,2,2,2,12))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2 run3,&& test "$$($(call casc_consumer_opmodes,$(casc_addend_dir)/_addend_g1_tie_$(r).log))" = "9'110010101 9'000010101 ")
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,flow1 flow2,&& test "$$(grep -c 'modes inferred: MULT_ADD_C x2, MULT_ADD_C_CASC x1, MULT_ADD x1$$' $(casc_addend_dir)/_addend_g1_tie_$(r).log)" = 1)
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,flow1 flow2,&& $(call casc_report,$(casc_addend_dir)/_addend_g1_tie_$(r).log,2,2,2,12))
qlf_k6n10f-dspv4_casc_addend_verify += && cmp $(casc_addend_dir)/_addend_g1_tie_flow1.blif $(casc_addend_dir)/_addend_g1_tie_flow2.blif
# One of the two cells' results also leaves on a port: that cell declines, and
# the other takes the $add, in both line orders.
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2,&& grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD_C_CASC x1, MULT_ADD x1$$' $(casc_addend_dir)/_addend_g1_tie_partial_$(r).log)
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2,&& $(call casc_found,$(casc_addend_dir)/_addend_g1_tie_partial_$(r).log,2,0))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2,&& $(call casc_wired,$(casc_addend_dir)/_addend_g1_tie_partial_$(r).log,2,3))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2,&& $(call casc_report,$(casc_addend_dir)/_addend_g1_tie_partial_$(r).log,2,2,2,12))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2,&& $(call casc_declined,$(casc_addend_dir)/_addend_g1_tie_partial_$(r).log,1,$(casc_other_adder_reader)))
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach r,run1 run2,&& ! grep -q 'cascade links refused' $(casc_addend_dir)/_addend_g1_tie_partial_$(r).log)
# Grouping 2 on a consumer with PREG: the $add goes.
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT_ADD_C x1$$' $(casc_addend_dir)/_addend_g2_preg.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_g2_preg.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_g2_preg.log,1,2)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_g2_preg.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_no_declined,$(casc_addend_dir)/_addend_g2_preg.log)
# A signed link and an unsigned k, padded to a signed value: the $add goes and
# k moves to C, in both groupings.
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT_ADD_C x1$$' $(casc_addend_dir)/_addend_g2_k_padded.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_g2_k_padded.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_g2_k_padded.log,1,2)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_g2_k_padded.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_addend_verify += && grep -q 'modes inferred: MULT_ADD_C_CASC x1, MULT x1$$' $(casc_addend_dir)/_addend_g1_k_padded.log
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_found,$(casc_addend_dir)/_addend_g1_k_padded.log,1,0)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_wired,$(casc_addend_dir)/_addend_g1_k_padded.log,1,1)
qlf_k6n10f-dspv4_casc_addend_verify += && $(call casc_report,$(casc_addend_dir)/_addend_g1_k_padded.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_addend_verify += $(foreach b,_addend_g2_k_padded _addend_g1_k_padded,&& $(call casc_no_declined,$(casc_addend_dir)/$(b).log))
# No block here refuses a link.
qlf_k6n10f-dspv4_casc_addend_verify += && ! grep -q 'cascade link' $(casc_addend_dir)/*.log
casc_addend_refused_dir = qlf_k6n10f/dspv4_casc_addend_refused
$(casc_addend_refused_dir)/ok: $(wildcard $(casc_addend_refused_dir)/*.v)
# Grouping 1 with a registered link that cannot move: rule 1 refuses the link,
# so the $add stays with it.
qlf_k6n10f-dspv4_casc_addend_refused_verify = grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1, MULT x1$$' $(casc_addend_refused_dir)/_addend_reglink.log
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_found,$(casc_addend_refused_dir)/_addend_reglink.log,2,1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_reason,$(casc_addend_refused_dir)/_addend_reglink.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_wired,$(casc_addend_refused_dir)/_addend_reglink.log,1,1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_not_moved,$(casc_addend_refused_dir)/_addend_reglink.log,$(casc_other_reader),1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_moved,$(casc_addend_refused_dir)/_addend_reglink.log,0)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && test "$$(grep -c 'grouping 1, .* folds' $(casc_addend_refused_dir)/_addend_reglink.log)" = 1
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_report,$(casc_addend_refused_dir)/_addend_reglink.log,1,1,2,12)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_ranked,$(casc_addend_refused_dir)/_addend_reglink.log,1,$(casc_other_reader))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_ranked,$(casc_addend_refused_dir)/_addend_reglink.log,1,$(casc_registered))
# Grouping 2 with the register on t: the $add is the reader of the source's P.
qlf_k6n10f-dspv4_casc_addend_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_addend_refused_dir)/_reglink_grp2_creg.log
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_found,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,1,1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_reason,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,$(casc_registered),1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_not_moved,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,$(casc_other_reader),1)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_moved,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,0)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_report,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,0,0,0,12)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_ranked,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,1,$(casc_other_reader))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_ranked,$(casc_addend_refused_dir)/_reglink_grp2_creg.log,1,$(casc_registered))
qlf_k6n10f-dspv4_casc_addend_refused_verify += $(foreach b,_addend_reglink _reglink_grp2_creg,&& ! grep -q 'link register(s) moved' $(casc_addend_refused_dir)/$(b).log)
# Grouping 2: a failed check refuses the link, with its reason, on the stopped
# run and in the whole flow.
casc_g2_refusal = grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_addend_refused_dir)/$(1).log \
  && $(call casc_found,$(casc_addend_refused_dir)/$(1).log,$(2),1) \
  && $(call casc_reason,$(casc_addend_refused_dir)/$(1).log,$(3),1) \
  && $(call casc_report,$(casc_addend_refused_dir)/$(1).log,0,0,0,12) \
  && $(call casc_ranked,$(casc_addend_refused_dir)/$(1).log,1,$(3)) \
  && test "$$(grep -c 'modes inferred: MULT_ADD_C x2$$' $(casc_addend_refused_dir)/$(1)_flow.log)" = 1 \
  && $(call casc_report,$(casc_addend_refused_dir)/$(1)_flow.log,0,0,0,12) \
  && $(call casc_ranked,$(casc_addend_refused_dir)/$(1)_flow.log,1,$(3))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_shared,0,$(casc_other_adder_reader))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_narrow,1,$(casc_addend_narrow))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_link_narrow,1,$(casc_too_narrow))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_unsigned,0,$(casc_addend_unsigned))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_pad,0,$(casc_unsigned))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_unsigned_in_pad,0,$(casc_unsigned))
# A signed link and an unsigned k: the $add is unsigned, so the link would be
# zero-extended. Grouping 2 refuses it by the addend guard, and by the finder's
# zero-extension check on t when t has constant zero bits above the sum.
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_k_unsigned,0,$(casc_addend_unsigned))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_k_unsigned_wide,0,$(casc_unsigned))
# Grouping 2 read shifted, or with another cell's bits above the wire: no
# attempt, so no candidate and no reason.
qlf_k6n10f-dspv4_casc_addend_refused_verify += $(foreach b,_addend_g2_slice _addend_g2_in_slice,&& grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_addend_refused_dir)/$(b).log)
qlf_k6n10f-dspv4_casc_addend_refused_verify += $(foreach b,_addend_g2_in_multicell _addend_g2_multicell,&& grep -q 'modes inferred: MULT_ADD_C x2, MULT x1$$' $(casc_addend_refused_dir)/$(b).log)
qlf_k6n10f-dspv4_casc_addend_refused_verify += $(foreach b,_addend_g2_slice _addend_g2_in_slice _addend_g2_in_multicell _addend_g2_multicell,&& $(call casc_found,$(casc_addend_refused_dir)/$(b).log,0,0))
qlf_k6n10f-dspv4_casc_addend_refused_verify += $(foreach b,_addend_g2_slice _addend_g2_in_slice _addend_g2_in_multicell _addend_g2_multicell,&& $(call casc_report,$(casc_addend_refused_dir)/$(b).log,0,0,0,12))
qlf_k6n10f-dspv4_casc_addend_refused_verify += $(foreach b,_addend_g2_slice _addend_g2_in_slice _addend_g2_in_multicell _addend_g2_multicell,&& ! grep -q 'cascade links refused' $(casc_addend_refused_dir)/$(b).log)
# Grouping 1: a failed check declines the fold; the plain link is made, and
# the reason is in the declined list, not the refused one.
casc_g1_decline = grep -q 'modes inferred: MULT_ADD x1, MULT x1$$' $(casc_addend_refused_dir)/$(1).log \
  && $(call casc_found,$(casc_addend_refused_dir)/$(1).log,1,0) \
  && $(call casc_wired,$(casc_addend_refused_dir)/$(1).log,1,0) \
  && $(call casc_report,$(casc_addend_refused_dir)/$(1).log,1,1,2,12) \
  && $(call casc_declined,$(casc_addend_refused_dir)/$(1).log,1,$(2)) \
  && ! grep -q 'cascade links refused' $(casc_addend_refused_dir)/$(1).log
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_narrow,$(casc_addend_narrow))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_shared,$(casc_other_adder_reader))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_unsigned,$(casc_addend_unsigned))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_wide_y,$(casc_addend_wide))
# Grouping 1 on a consumer with PREG: k would be registered. The plain link stays.
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_preg,$(casc_addend_registered))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && ! grep -q 'grouping 1, .* folds' $(casc_addend_refused_dir)/_addend_g1_preg.log
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_k_unsigned,$(casc_addend_unsigned))
# Grouping 1 below an accumulator: s must hold the whole 50-bit port, so a
# 40-bit s declines the fold in rule 1's walk, after the finder took it.
casc_full_port_log = $(casc_addend_refused_dir)/_addend_g1_full_port.log
qlf_k6n10f-dspv4_casc_addend_refused_verify += && grep -q 'modes inferred: MULT_ADD x1, MULT_ACC x1$$' $(casc_full_port_log)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_found,$(casc_full_port_log),1,0)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_wired,$(casc_full_port_log),1,0)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_report,$(casc_full_port_log),1,1,2,12)
qlf_k6n10f-dspv4_casc_addend_refused_verify += && test "$$(grep -c 'grouping 1, .* folds' $(casc_full_port_log))" = 1
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_declined,$(casc_full_port_log),1,$(casc_addend_narrow))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && ! grep -q 'cascade links refused' $(casc_full_port_log)
# A wire marked keep on the $add's sum (grouping 2) or on the consumer's result
# (grouping 1) stops the fold: the $add stays and drives the kept wire.
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g2_refusal,_addend_g2_kept,0,$(casc_addend_kept))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && $(call casc_g1_decline,_addend_g1_kept,$(casc_addend_kept))
qlf_k6n10f-dspv4_casc_addend_refused_verify += && ! grep -q 'grouping 1, .* folds' $(casc_addend_refused_dir)/_addend_g1_kept.log

# A loop with no register: the link into the cell first in name order is
# dropped, once, and the rest links. casc_loop_no_register takes a block, its
# candidate and refused counts, the number of cells that read PCIN and C, the
# links, the longest chain and the limit. The stopped log also names the head.
casc_loop_dir = qlf_k6n10f/dspv4_casc_loop_no_register
$(casc_loop_dir)/ok: $(wildcard $(casc_loop_dir)/*.v)
casc_loop_head = test "$$(grep -c 'cascade: .* is a head now: its loop lost a link$$' $(1))" = 1
casc_loop_no_register = $(call casc_found,$(casc_loop_dir)/$(1).log,$(2),$(3)) && $(call casc_reason,$(casc_loop_dir)/$(1).log,$(casc_loop),1) && $(call casc_loop_head,$(casc_loop_dir)/$(1).log) && $(call casc_wired,$(casc_loop_dir)/$(1).log,$(4),$(5)) && $(call casc_report,$(casc_loop_dir)/$(1).log,$(6),1,$(7),$(8)) && $(call casc_report,$(casc_loop_dir)/$(1)_flow.log,$(6),1,$(7),$(8)) && $(call casc_ranked,$(casc_loop_dir)/$(1)_flow.log,1,$(casc_loop))
qlf_k6n10f-dspv4_casc_loop_no_register_verify = $(call casc_loop_no_register,_ring2,2,1,1,1,1,2,2)
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && $(call casc_loop_no_register,_ring2_swapped,2,1,1,1,1,2,12)
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && $(call casc_loop_no_register,_ring3,3,1,2,1,2,3,12)
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && $(call casc_loop_no_register,_ring2_tail,3,2,1,2,1,2,12)
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && $(call casc_reason,$(casc_loop_dir)/_ring2_tail.log,$(casc_shorter),1)
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_loop_dir)/_ring2.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_loop_dir)/_ring2_flow.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_loop_dir)/_ring2_swapped.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ADD x1$$' $(casc_loop_dir)/_ring2_swapped_flow.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1$$' $(casc_loop_dir)/_ring3.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD x2, MULT_ADD_C x1$$' $(casc_loop_dir)/_ring3_flow.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_loop_dir)/_ring2_tail.log
qlf_k6n10f-dspv4_casc_loop_no_register_verify += && grep -q 'modes inferred: MULT_ADD_C x2, MULT_ADD x1$$' $(casc_loop_dir)/_ring2_tail_flow.log
dffs_verify = true
shreg_verify = true
full_adder_verify = true
qlf_k6n10f-dsp_mult_verify = true
qlf_k6n10f-dsp_simd_verify = true
qlf_k6n10f-dsp_macc_verify = true
qlf_k6n10f-dsp_madd_verify = true
qlf_k6n10f-ioff_verify = true
qlf_k6n10f-sdffr_inst_verify = true
qlf_k6n10f-ioff_rst_verify = true
qlf_k6n10f-ioff_pol_verify = true
qlf_k6n10f-ioff_flags_verify = true
qlf_k6n10f-ioff_blif_verify = true
qlf_k6n10f-io_translate_verify = true
# The help text must list the option and the link step (help used to crash).
qlf_k6n10f-synth_options_verify = true
qlf_k6n10f-rel_ip_blif_verify = grep -q -- '-rel_ip_blif <file>' qlf_k6n10f/rel_ip_blif/rel_ip_blif.log && grep -q 'link_rel_ips:' qlf_k6n10f/rel_ip_blif/rel_ip_blif.log
# Expected-failure tests: yosys must exit non-zero AND the log must carry the intended error.
qlf_k6n10f/rel_ip_blif_noannot_negative = 1
qlf_k6n10f-rel_ip_blif_noannot_verify = grep -q 'carries no relative-placement annotation' qlf_k6n10f/rel_ip_blif_noannot/rel_ip_blif_noannot.log
qlf_k6n10f/rel_ip_blif_notflat_negative = 1
qlf_k6n10f-rel_ip_blif_notflat_verify = grep -q 'both have contents' qlf_k6n10f/rel_ip_blif_notflat/rel_ip_blif_notflat.log
qlf_k6n10f/rel_ip_blif_unquoted_negative = 1
qlf_k6n10f-rel_ip_blif_unquoted_verify = grep -q 'must be a quoted string' qlf_k6n10f/rel_ip_blif_unquoted/rel_ip_blif_unquoted.log
qlf_k6n10f/rel_ip_blif_badstub_negative = 1
qlf_k6n10f-rel_ip_blif_badstub_verify = grep -q "port 'd' is 1 bits wide in the IP netlist but 2 in the stub" qlf_k6n10f/rel_ip_blif_badstub/rel_ip_blif_badstub.log
qlf_k6n10f/rel_ip_blif_noprim_negative = 1
qlf_k6n10f-rel_ip_blif_noprim_verify = grep -q "primitive 'QL_OTHER_PRIM', which the cell library does not define" qlf_k6n10f/rel_ip_blif_noprim/rel_ip_blif_noprim.log

# Which width lands on which multiply port. Counts cannot tell the two apart.
qlf_k6n10f-dspv4_preadd_widths_verify = grep -q 'modes inferred: PREADD_B_MULT_A x4, PREADD_A_MULT_B x2' qlf_k6n10f/dspv4_preadd_widths/dspv4_preadd_widths.log
# No pre-adder mode anywhere. Asserted this way rather than as a MULT count
# because the pass runs twice and splits the count between the two lines.
qlf_k6n10f-dspv4_preadd_refused_verify = ! grep -q 'modes inferred:.*PREADD' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '2 x  pre-adder: it truncates its own sum, which the DSP would not' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  pre-adder: its operand signedness differs from the multiply port' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '5 x  pre-adder: its sum may exceed the multiplier port' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  pre-adder: the multiply operand pads its sum instead of extending its sign' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  multiply: 19x32 (signed x signed) does not fit the 32x18 ports' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '2 x  multiply: 18x20 (unsigned x unsigned) does not fit the 32x18 ports; an unsigned operand needs a spare bit' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  multiply: 32x8 (unsigned x unsigned) does not fit the 32x18 ports; an unsigned operand needs a spare bit' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  multiply: 19x20 (unsigned x unsigned) does not fit the 32x18 ports; an unsigned operand needs a spare bit' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log

# Five modes in one design. Counts cannot tell PREADD_A_SUB_B from
# PREADD_B_SUB_A, and for the reversed-operand shape the mode name is the only
# evidence the pass did not swap D and A.
qlf_k6n10f-dspv4_preadd_modes_verify = grep -q 'modes inferred: PREADD_A_SUB_B x2, PREADD_B_SUB_A x1, PREADD_B_MULT_A x1, PREADD_A_MULT_B_C x1' qlf_k6n10f/dspv4_preadd_modes/dspv4_preadd_modes.log

# A refused pre-adder must report MULT, not a PREADD mode -- the cell counts
# in the .tcl cannot tell a refusal from a fold that never matched.
qlf_k6n10f-dspv4_preadd_adreg_trunc_verify = grep -q 'modes inferred: MULT x3' qlf_k6n10f/dspv4_preadd_adreg_trunc/dspv4_preadd_adreg_trunc.log
qlf_k6n10f-dspv4_preadd_adreg_trunc_verify += && grep -q '2 x  pre-adder: the multiply reads fewer bits of its registered sum than it produces' qlf_k6n10f/dspv4_preadd_adreg_trunc/dspv4_preadd_adreg_trunc.log
qlf_k6n10f-dspv4_preadd_adreg_trunc_verify += && grep -q '1 x  pre-adder: an unsigned subtract wraps where the DSP signs' qlf_k6n10f/dspv4_preadd_adreg_trunc/dspv4_preadd_adreg_trunc.log


# Fifteen shapes, two paths. Counts cannot tell PREADD_A from PREADD_B; the
# swap onto B1/B2 is the second B-path word.
qlf_k6n10f-dspv4_preadd_regs_verify = grep -q 'modes inferred: PREADD_A_MULT_B x12, PREADD_B_MULT_A x3' qlf_k6n10f/dspv4_preadd_regs/dspv4_preadd_regs.log
# The two four-enable cells name the B chain they give up.
qlf_k6n10f-dspv4_preadd_regs_verify += && grep -q '2 x  B register chain given up: the cell would need more than 3 clock enables' qlf_k6n10f/dspv4_preadd_regs/dspv4_preadd_regs.log

# One inverter per active-low enable signal (aurora2 #2971). The run reads the
# inverter count after ql_dspv4; here the log must show the cell was inferred
# and that ql_dsp4_check did not count one enable as several.
qlf_k6n10f-dspv4_enable_inverter_shared_verify = grep -q 'modes inferred: MULT_ADD_C x1' qlf_k6n10f/dspv4_enable_inverter_shared/dspv4_enable_inverter_shared.log
qlf_k6n10f-dspv4_enable_inverter_shared_verify += && ! grep -q 'distinct clock enables' qlf_k6n10f/dspv4_enable_inverter_shared/dspv4_enable_inverter_shared.log
# A QL_DSP4 the techmap refuses stops synthesis (aurora2 #2973). The refused
# run is expected to fail and its log must name each of the four cells; the twin
# has the same four cells with the rule satisfied and must map.
qlf_k6n10f/dspv4_techmap_refused_stops_negative = 1
qlf_k6n10f-dspv4_techmap_refused_stops_verify = grep -q 'selection is not empty: t:QL_DSP4' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'dspv4_techmap_refused_stops/u_w$$' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'dspv4_techmap_refused_stops/u_y$$' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'dspv4_techmap_refused_stops/u_carry$$' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'dspv4_techmap_refused_stops/u_carryp$$' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
# The refused run also says why, for each of the four cells.
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'refused_stops.u_w: .*It breaks: reserved W encoding (W_SEL = 10)' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'refused_stops.u_y: .*It breaks: reserved Y encoding (Y_SEL = 10)' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'refused_stops.u_carry: .*It breaks: CARRYINSEL = 001 is not a carry source' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_refused_stops_verify += && grep -q 'refused_stops.u_carryp: .*It breaks: the carry register (CARRYINSEL = 100) with P fed back' qlf_k6n10f/dspv4_techmap_refused_stops/dspv4_techmap_refused_stops.log
qlf_k6n10f-dspv4_techmap_twin_maps_verify = true

# ql_dsp4_explain on its own (aurora2 #2973): two rules in one message, and a
# cell that breaks none of the known rules is reported as unexplained.
qlf_k6n10f-dspv4_techmap_reason_verify = grep -q 'dspv4_techmap_reason.u_two: .*It breaks: CARRYINSEL = 001 is not a carry source.*; reserved W encoding (W_SEL = 10)' qlf_k6n10f/dspv4_techmap_reason/dspv4_techmap_reason.log
qlf_k6n10f-dspv4_techmap_reason_verify += && grep -q 'dspv4_techmap_reason.u_clean: .*No known rule explains it' qlf_k6n10f/dspv4_techmap_reason/dspv4_techmap_reason.log
qlf_k6n10f-dspv4_techmap_reason_verify += && ! grep -q 'dspv4_techmap_reason.u_clean: .*It breaks' qlf_k6n10f/dspv4_techmap_reason/dspv4_techmap_reason.log

# The design rules of the techmap (openphy-turnkey-flow #2173, aurora2 #2973). The
# refused run is expected to fail and its log must give the rule for each of
# the eight cells; the twin has cells with the rule satisfied and they must map.
qlf_k6n10f/dspv4_techmap_refused_drc_negative = 1
qlf_k6n10f-dspv4_techmap_refused_drc_verify = grep -q 'selection is not empty: t:QL_DSP4' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_simd11: .*It breaks: USE_SIMD = 11, a segmentation that does not exist' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_simdwxy: .*It breaks: SIMD with more than one of W, X and Y selected' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_simdrss: .*It breaks: SIMD with USE_RSS' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_simdcarry: .*It breaks: SIMD with a carry-in from CCIN or the carry register' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_uwithoutv: .*It breaks: X = U without Y = V' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_zres: .*It breaks: reserved Z encoding (Z_SEL = 111)' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_maccext: .*It breaks: MACC_EXT (Z_SEL = 100) with ALUMODE != 00' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_ce4: .*It breaks: 4 clock-enable nets on the registers in use' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_refused_drc_verify += && grep -q 'refused_drc.u_ce4open: .*It breaks: 4 clock-enable nets on the registers in use' qlf_k6n10f/dspv4_techmap_refused_drc/dspv4_techmap_refused_drc.log
qlf_k6n10f-dspv4_techmap_twin_drc_maps_verify = true
# GND and VCC cells become constants before the DSP-V4 techmap (aurora2 #2970).
# A carry-in on a GND cell folds the lone MREG; a live carry-in keeps the M banks.
qlf_k6n10f-dspv4_synplify_gnd_cin_folds_verify = true
qlf_k6n10f-dspv4_synplify_live_cin_keeps_m_verify = true

# A tied-high clock enable counts against the crossbar's three inputs (aurora2
# #2972). The evict block must give up exactly one port, B, and the keep block
# none; the cells that remain must not trip the check pass.
qlf_k6n10f-dspv4_enable_tied_high_evicts_verify = grep -q '1 x  B register chain given up: the cell would need more than 3 clock enables' qlf_k6n10f/dspv4_enable_tied_high_evicts/dspv4_enable_tied_high_evicts.log
qlf_k6n10f-dspv4_enable_tied_high_evicts_verify += && ! grep -q 'distinct clock enables' qlf_k6n10f/dspv4_enable_tied_high_evicts/dspv4_enable_tied_high_evicts.log
# The shared block gives up D and keeps B: B and C hold the same tied-high net, so
# giving up B frees no slot. B is given up once, by the evict block, not twice.
qlf_k6n10f-dspv4_enable_tied_high_evicts_verify += && grep -q '1 x  D register chain given up: the cell would need more than 3 clock enables' qlf_k6n10f/dspv4_enable_tied_high_evicts/dspv4_enable_tied_high_evicts.log
qlf_k6n10f-dspv4_enable_tied_high_evicts_verify += && ! grep -q '2 x  B register chain given up' qlf_k6n10f/dspv4_enable_tied_high_evicts/dspv4_enable_tied_high_evicts.log
# The check pass: the four-net cell warns, the three-net cell does not.
qlf_k6n10f-dspv4_enable_tied_high_check_verify = grep -q 'u_warns.u: 4 distinct clock enables' qlf_k6n10f/dspv4_enable_tied_high_check/dspv4_enable_tied_high_check.log
qlf_k6n10f-dspv4_enable_tied_high_check_verify += && ! grep -q 'u_fits.u: [0-9]* distinct clock enables' qlf_k6n10f/dspv4_enable_tied_high_check/dspv4_enable_tied_high_check.log
