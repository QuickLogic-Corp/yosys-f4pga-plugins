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
	qlf_k6n10f/dspv4_preadd_a \
	qlf_k6n10f/dspv4_preadd_width_ok \
	qlf_k6n10f/dspv4_preadd_width_edge \
	qlf_k6n10f/dspv4_preadd_width_over \
	qlf_k6n10f/dspv4_preadd_width_const \
	qlf_k6n10f/dspv4_preadd_pad \
	qlf_k6n10f/dspv4_preadd_unsigned \
	qlf_k6n10f/dspv4_preadd_trunc \
	qlf_k6n10f/dspv4_preadd_a_sub \
	qlf_k6n10f/dspv4_preadd_order \
	qlf_k6n10f/dspv4_preadd_addc \
	qlf_k6n10f/dspv4_preadd_a_macc \
	qlf_k6n10f/dspv4_preadd_b \
	qlf_k6n10f/dspv4_preadd_b_sub \
	qlf_k6n10f/dspv4_xpath \
	qlf_k6n10f/dspv4_xpath_sub \
	qlf_k6n10f/dspv4_preadd_both \
	qlf_k6n10f/dspv4_preadd_shared \
	qlf_k6n10f/dspv4_preadd_square \
	qlf_k6n10f/dspv4_mult_add_self \
	qlf_k6n10f/dspv4_mult_mreg_add_self \
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
     qlf_k6n10f/bram_asymmetric_wider_read

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

# Which mode the pass chose. The cell counts in the .tcl cannot tell
# PREADD_A_MULT_B from PREADD_B_MULT_A -- both emit one QL_DSP4_PREADD and one
# QL_DSP4_MULT -- so without these the A/B decision is untested. A refused
# shape must report MULT, not a PREADD mode: that is what says the guard
# refused rather than folded something it should not have.
qlf_k6n10f-dspv4_preadd_a_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_preadd_a/dspv4_preadd_a.log
qlf_k6n10f-dspv4_preadd_width_ok_verify = grep -q 'modes inferred: PREADD_B_MULT_A x1' qlf_k6n10f/dspv4_preadd_width_ok/dspv4_preadd_width_ok.log
qlf_k6n10f-dspv4_preadd_width_edge_verify = grep -q 'modes inferred: PREADD_B_MULT_A x1' qlf_k6n10f/dspv4_preadd_width_edge/dspv4_preadd_width_edge.log
qlf_k6n10f-dspv4_preadd_width_const_verify = grep -q 'modes inferred: PREADD_B_MULT_A x1' qlf_k6n10f/dspv4_preadd_width_const/dspv4_preadd_width_const.log
qlf_k6n10f-dspv4_preadd_width_over_verify = grep -q 'modes inferred: MULT x2' qlf_k6n10f/dspv4_preadd_width_over/dspv4_preadd_width_over.log
qlf_k6n10f-dspv4_preadd_pad_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_pad/dspv4_preadd_pad.log
qlf_k6n10f-dspv4_preadd_trunc_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_trunc/dspv4_preadd_trunc.log
qlf_k6n10f-dspv4_preadd_unsigned_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_unsigned/dspv4_preadd_unsigned.log

qlf_k6n10f-dspv4_preadd_b_verify = grep -q 'modes inferred: PREADD_B_MULT_A x1' qlf_k6n10f/dspv4_preadd_b/dspv4_preadd_b.log
qlf_k6n10f-dspv4_preadd_a_sub_verify = grep -q 'modes inferred: PREADD_A_SUB_B x1' qlf_k6n10f/dspv4_preadd_a_sub/dspv4_preadd_a_sub.log
qlf_k6n10f-dspv4_preadd_b_sub_verify = grep -q 'modes inferred: PREADD_B_SUB_A x1' qlf_k6n10f/dspv4_preadd_b_sub/dspv4_preadd_b_sub.log
qlf_k6n10f-dspv4_preadd_addc_verify = grep -q 'modes inferred: PREADD_A_MULT_B_C x1' qlf_k6n10f/dspv4_preadd_addc/dspv4_preadd_addc.log
qlf_k6n10f-dspv4_preadd_a_macc_verify = grep -q 'modes inferred:.*PREADD_A_MACC x1' qlf_k6n10f/dspv4_preadd_a_macc/dspv4_preadd_a_macc.log
qlf_k6n10f-dspv4_preadd_a_macc_verify += && grep -q 'modes inferred:.*PREADD_A_MACC_C x1' qlf_k6n10f/dspv4_preadd_a_macc/dspv4_preadd_a_macc.log
qlf_k6n10f-dspv4_preadd_a_macc_verify += && grep -q 'modes inferred:.*PREADD_B_MACC_C x1' qlf_k6n10f/dspv4_preadd_a_macc/dspv4_preadd_a_macc.log
# (A - D) * B. Subtract is not commutative, so a swap would compute
# (D - A) * B. The SUB mode is the evidence the pass did not swap.
qlf_k6n10f-dspv4_preadd_order_verify = grep -q 'modes inferred: PREADD_A_SUB_B x1' qlf_k6n10f/dspv4_preadd_order/dspv4_preadd_order.log
# Two sums, 19-bit and 9-bit. The wider one is on the A port, so taking
# the A side is the rule 'absorb the wider' working.
qlf_k6n10f-dspv4_preadd_both_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_preadd_both/dspv4_preadd_both.log
qlf_k6n10f-dspv4_preadd_shared_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_preadd_shared/dspv4_preadd_shared.log
# Squaring is refused, so no pre-adder mode at all.
qlf_k6n10f-dspv4_preadd_square_verify = grep -q 'modes inferred: MULT x1' qlf_k6n10f/dspv4_preadd_square/dspv4_preadd_square.log
# The cross-path shape folds to a plain PREADD mode. XPATH has no
# separate control word -- PREADD_A_MULT_B already covers it.
qlf_k6n10f-dspv4_xpath_verify = grep -q 'modes inferred: PREADD_A_MULT_B x1' qlf_k6n10f/dspv4_xpath/dspv4_xpath.log
qlf_k6n10f-dspv4_xpath_sub_verify = grep -q 'modes inferred: PREADD_A_SUB_B x1' qlf_k6n10f/dspv4_xpath_sub/dspv4_xpath_sub.log
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
