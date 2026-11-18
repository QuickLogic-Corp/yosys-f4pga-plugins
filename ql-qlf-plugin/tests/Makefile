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
	fp_owner \
	fp_owner_bram_merge \
	fp_owner_clash \
	fp_owner_dspv4 \
	fp_owner_flat \
	fp_owner_hdlname \
	fp_owner_rel_ip \
	fp_owner_sweep \
	fp_owner_synplify \
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
	qlf_k6n10f/dspv4_casc_links \
	qlf_k6n10f/dspv4_casc_refused \
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
# A chain the user instantiated is not the pass's to link: no cell inferred,
# no chain report, and the second cell still reads the first on C.
casc_links_dir = qlf_k6n10f/dspv4_casc_links
qlf_k6n10f-dspv4_casc_links_verify = grep -q 'inferred 0 QL_DSP4 cell(s)' $(casc_links_dir)/_macro.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'ql_dspv4: cascade' $(casc_links_dir)/_macro.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q 'modes inferred' $(casc_links_dir)/_macro.log
qlf_k6n10f-dspv4_casc_links_verify += && ! grep -q -E 'connect .(PCIN|PCOUT) ' $(casc_links_dir)/_macro.log
qlf_k6n10f-dspv4_casc_links_verify += && grep -q -F 'connect \C { \head_p [35]' $(casc_links_dir)/_macro.log
# What the finder makes of each block: how many candidate links, and how many
# reads it refuses itself. casc_found takes the block's log and the two counts.
casc_found = test "$$(grep -c 'cascade candidate:' $(1))" = $(2) && test "$$(grep -c 'cascade link refused:' $(1))" = $(3)
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_macro.log,0,0)
qlf_k6n10f-dspv4_casc_links_verify += && grep -q 'modes inferred: MULT_ADD_C x4, MULT x1$$' $(casc_links_dir)/_chain.log
qlf_k6n10f-dspv4_casc_links_verify += && $(call casc_found,$(casc_links_dir)/_chain.log,4,0)
casc_refused_dir = qlf_k6n10f/dspv4_casc_refused
casc_read_unsigned = cascade link refused: .*: link is read unsigned, and PCIN sign-extends$$
qlf_k6n10f-dspv4_casc_refused_verify = grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_unsigned.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_unsigned.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '$(casc_read_unsigned)' $(casc_refused_dir)/_unsigned.log
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT x1$$' $(casc_refused_dir)/_pad.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_pad.log,0,1)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q '$(casc_read_unsigned)' $(casc_refused_dir)/_pad.log
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x2$$' $(casc_refused_dir)/_slice.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_slice.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT x2, MULT_ADD_C x1$$' $(casc_refused_dir)/_multicell.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_multicell.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_SUB_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_sub.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_sub.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: MULT_ADD_C x1, MULT_ACC_C x1$$' $(casc_refused_dir)/_acc_tail.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_acc_tail.log,0,0)
qlf_k6n10f-dspv4_casc_refused_verify += && grep -q 'modes inferred: PREADD_B_MULT_A_C x1, MULT_ADD_C x1$$' $(casc_refused_dir)/_preadd_b.log
qlf_k6n10f-dspv4_casc_refused_verify += && $(call casc_found,$(casc_refused_dir)/_preadd_b.log,0,0)
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
