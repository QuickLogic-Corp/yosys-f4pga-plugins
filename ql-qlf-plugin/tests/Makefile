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
	qlf_k6n10f/dspv4_xpath_sub \
	qlf_k6n10f/dspv4_preadd_both \
	qlf_k6n10f/dspv4_preadd_shared \
	qlf_k6n10f/dspv4_preadd_square \
	qlf_k6n10f/dspv4_preadd_preg_wrap \
	qlf_k6n10f/dspv4_preadd_adreg_trunc \
	qlf_k6n10f/dspv4_preadd_regs \
	qlf_k6n10f/dspv4_preadd_adreg_rst \
	qlf_k6n10f/dspv4_preadd_adreg_evict \
	qlf_k6n10f/dspv4_leftover_reasons \
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
     qlf_k6n10f/dspv4_preg_rst_post_synth_sim

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
qlf_k6n10f-dspv4_preadd_sub_unsigned_verify = grep -q 'modes inferred:.*PREADD_A_SUB_B x1' qlf_k6n10f/dspv4_preadd_sub_unsigned/dspv4_preadd_sub_unsigned.log
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
qlf_k6n10f-dspv4_preadd_shared_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_preadd_shared/dspv4_preadd_shared.log
# Squaring is refused, so no pre-adder mode at all.
qlf_k6n10f-dspv4_preadd_square_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
qlf_k6n10f-dspv4_preadd_square_verify += && grep -q '1 x  pre-adder: it feeds both multiply operands (squaring)' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
# The cross-path shape folds to a plain PREADD mode. XPATH has no
# separate control word -- PREADD_A_MULT_B already covers it.
qlf_k6n10f-dspv4_xpath_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_sub_verify = grep -q 'modes inferred: PREADD_A_SUB_B x1' qlf_k6n10f/dspv4_xpath_sub/dspv4_xpath_sub.log
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
qlf_k6n10f-dspv4_preadd_widths_verify = grep -q 'modes inferred: PREADD_B_MULT_A x3, PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_preadd_widths/dspv4_preadd_widths.log
# No pre-adder mode anywhere. Asserted this way rather than as a MULT count
# because the pass runs twice and splits the count between the two lines.
qlf_k6n10f-dspv4_preadd_refused_verify = ! grep -q 'modes inferred:.*PREADD' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  pre-adder: it truncates its own sum, which the DSP would not' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  pre-adder: its operand signedness differs from the multiply port' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  pre-adder: its sum may exceed the multiplier port' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  pre-adder: the multiply operand pads its sum instead of extending its sign' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log
qlf_k6n10f-dspv4_preadd_refused_verify += && grep -q '1 x  multiply: 19x32 (signed x signed) does not fit the 32x18 ports' qlf_k6n10f/dspv4_preadd_refused/dspv4_preadd_refused.log

# Five modes in one design. Counts cannot tell PREADD_A_SUB_B from
# PREADD_B_SUB_A, and for the reversed-operand shape the mode name is the only
# evidence the pass did not swap D and A.
qlf_k6n10f-dspv4_preadd_modes_verify = grep -q 'modes inferred: PREADD_A_SUB_B x2, PREADD_B_SUB_A x1, PREADD_B_MULT_A x1, PREADD_A_MULT_B_C x1' qlf_k6n10f/dspv4_preadd_modes/dspv4_preadd_modes.log

# A refused pre-adder must report MULT, not a PREADD mode -- the cell counts
# in the .tcl cannot tell a refusal from a fold that never matched.
qlf_k6n10f-dspv4_preadd_adreg_trunc_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_adreg_trunc/dspv4_preadd_adreg_trunc.log
qlf_k6n10f-dspv4_preadd_adreg_trunc_verify += && grep -q '1 x  pre-adder: the multiply reads fewer bits of its registered sum than it produces' qlf_k6n10f/dspv4_preadd_adreg_trunc/dspv4_preadd_adreg_trunc.log


# Thirteen shapes, two paths. Counts cannot tell PREADD_A from PREADD_B; the
# swap onto B1/B2 is the second B-path word.
qlf_k6n10f-dspv4_preadd_regs_verify = grep -q 'modes inferred: PREADD_A_MULT_B x12, PREADD_B_MULT_A x2' qlf_k6n10f/dspv4_preadd_regs/dspv4_preadd_regs.log
# The two four-enable cells name the B chain they give up.
qlf_k6n10f-dspv4_preadd_regs_verify += && grep -q '2 x  B register chain given up: the cell would need more than 3 clock enables' qlf_k6n10f/dspv4_preadd_regs/dspv4_preadd_regs.log
