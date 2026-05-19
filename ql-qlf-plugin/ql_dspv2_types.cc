/*
 *  yosys -- Yosys Open SYnthesis Suite
 *
 *  Copyright (C) 2023  N. Engelhardt <nak@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include "kernel/log.h"
#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/sigtools.h"
#include "kernel/yosys.h"

#include <cstdint>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// ============================================================================


struct QlDSPV2TypesPass : public Pass {
	
	QlDSPV2TypesPass() : Pass("ql_dspv2_types", "Change QL_DSPV2 type to subtypes") {}

	void help() override
	{
		//   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
		log("\n");
		log("    ql_dspv2_types [selection]\n");
		log("\n");
		log("    This pass changes the type of QL_DSPV2 cells to different types based on the\n");
		log("    configuration of the cell.\n");
		log("\n");
	}
	
    bool replace_existing_pass() const override
    {
        return true;
    }

	static int get_const_port_value(RTLIL::Cell *cell, RTLIL::IdString port_name)
	{
		if (!cell->hasPort(port_name))
			log_error("Cell %s: port %s not found!\n",
					log_id(cell), log_id(port_name));

		RTLIL::SigSpec sig = cell->getPort(port_name);

		log_debug("Cell %s %s = %s\n",
			log_id(cell), log_id(port_name), log_signal(sig));

		if (!sig.is_fully_const())
			log_error("Cell %s: port %s is not constant (%s)\n",
					log_id(cell), log_id(port_name), log_signal(sig));

		RTLIL::Const c = sig.as_const();
		int value = c.as_int();

		log_debug("%s value: %d\n", log_id(port_name), value);

		return value;
	}

	uint32_t get_control_word(
		uint32_t feedback, //3 bits
		uint32_t output_select, //2 bits
		bool zcin_sel,
		bool padd_sel,
		bool sub
	) {
		uint32_t control_word = 0;

		control_word |= (feedback & 0b111) 		<< 5;  // top 3 bits
		control_word |= (output_select & 0b11)  << 3;
		control_word |= (zcin_sel ? 1u : 0u) 	<< 2;
		control_word |= (padd_sel ? 1u : 0u) 	<< 1;
		control_word |= (sub ? 1u : 0u);

		return control_word;
	}

	void add_bitwise_dffre_before_cell_input(RTLIL::Module *module,
											RTLIL::Cell *cell,
											RTLIL::IdString port)  // input port
	{
		SigSpec clk, rst;
		if (cell->hasPort(IdString("\\clk"))) clk = cell->getPort(IdString("\\clk"));
		if (cell->hasPort(IdString("\\reset"))) rst = cell->getPort(IdString("\\reset"));

		SigSpec input_sig = cell->getPort(port);
		int width = GetSize(input_sig);

		log("\nAdding bitwise dffre BEFORE %s.%s, width=%d\n", log_id(cell), log_id(port), width);

		// Create intermediate wire that will connect to the cell input
		Wire *reg_wire = module->addWire(
			module->uniquify(stringf("\\%s_%s_reg", log_id(cell), log_id(port))),
			width
		);

		// Rewire cell input to use the register output
		cell->setPort(port, reg_wire);

		// Instantiate one 1-bit dffre per bit
		for (int i = 0; i < width; i++) {
			Cell *dff = module->addCell(
				module->uniquify("\\dffre"),
				IdString("\\dffre")
			);

			SigBit bit_in = input_sig[i];           // original input bit
			SigBit bit_out = SigBit(reg_wire, i);   // intermediate reg wire bit

			dff->setPort(IdString("\\D"), SigSpec(bit_in));
			dff->setPort(IdString("\\Q"), SigSpec(bit_out));
			dff->setPort(IdString("\\C"), clk);
			dff->setPort(IdString("\\R"), rst);
			dff->setPort(IdString("\\E"), SigSpec());

			log_debug("Added bit %d dffre BEFORE: D=%s, Q=%s\n", i, log_signal(bit_in), log_signal(bit_out));
		}
	}


	void add_bitwise_dffre_after_cell_output(RTLIL::Module *module,
                                         RTLIL::Cell *cell,
                                         RTLIL::IdString port)  // output port
	{
		SigSpec clk, rst;
		if (cell->hasPort(IdString("\\clk"))) clk = cell->getPort(IdString("\\clk"));
		if (cell->hasPort(IdString("\\reset"))) rst = cell->getPort(IdString("\\reset"));

		SigSpec output_sig = cell->getPort(port);
		int width = GetSize(output_sig);

		log("\nAdding bitwise dffre AFTER %s.%s, width=%d\n", log_id(cell), log_id(port), width);

		// Create intermediate wire that will be the new cell output
		Wire *reg_wire = module->addWire(
			module->uniquify(stringf("\\%s_%s_reg", log_id(cell), log_id(port))),
			width
		);

		// Rewire cell output to drive the intermediate wire
		cell->setPort(port, reg_wire);

		// Instantiate one 1-bit dffre per bit
		for (int i = 0; i < width; i++) {
			Cell *dff = module->addCell(
				module->uniquify("\\dffre"),
				IdString("\\dffre")
			);

			SigBit bit_in = SigBit(reg_wire, i);   // intermediate wire bit drives D
			SigBit bit_out = output_sig[i];        // original output bit driven by Q

			dff->setPort(IdString("\\D"), SigSpec(bit_in));
			dff->setPort(IdString("\\Q"), SigSpec(bit_out));
			dff->setPort(IdString("\\C"), clk);
			dff->setPort(IdString("\\R"), rst);
			dff->setPort(IdString("\\E"), SigSpec());

			log_debug("Added bit %d dffre AFTER: D=%s, Q=%s\n", i, log_signal(bit_in), log_signal(bit_out));
		}
	}

	pool<RTLIL::SigBit> sigbits_set(RTLIL::SigSpec sig)
	{
		pool<RTLIL::SigBit> bits;
		for (auto b : sig)
			bits.insert(b);
		return bits;
	}


	void replace_drop_net_with_keep_net(
		RTLIL::Module *module,
		RTLIL::Cell *cell,
		RTLIL::IdString keep_port,
		RTLIL::IdString drop_port
	) {
		// Safety checks
		if (!cell->hasPort(keep_port) || !cell->hasPort(drop_port))
			log_error("Cell %s does not have required ports %s / %s\n",
					log_id(cell), log_id(keep_port), log_id(drop_port));

		SigMap sigmap(module);

		// Capture signals BEFORE modifying the cell
		RTLIL::SigSpec keep_sig = sigmap(cell->getPort(keep_port));
		RTLIL::SigSpec drop_sig = sigmap(cell->getPort(drop_port));

		auto drop_bits = sigbits_set(drop_sig);

		log_debug("\n[replace_drop_net_with_keep_net]\n");
		log_debug("  Cell        : %s\n", log_id(cell));
		log_debug("  Keep        : %s\n", log_signal(keep_sig));
		log_debug("  Drop        : %s\n", log_signal(drop_sig));

		// ----------------------------------------
		// Find all consumers of drop signal
		// ----------------------------------------
		for (auto c : module->cells())
		{
			for (auto &conn : c->connections())
			{
				RTLIL::SigSpec old_sig = sigmap(conn.second);
				bool uses_drop = false;

				for (auto bit : old_sig) {
					if (drop_bits.count(bit)) {
						uses_drop = true;
						break;
					}
				}

				if (!uses_drop)
					continue;

				// ----------------------------------------
				// Replace drop bits with keep bits
				// ----------------------------------------
				RTLIL::SigSpec new_sig = old_sig;
				new_sig.replace(drop_sig, keep_sig);

				c->setPort(conn.first, new_sig);

				log_debug("  Rewire     : %s.%s\n",
					log_id(c), log_id(conn.first));
				log_debug("               %s → %s\n",
					log_signal(old_sig),
					log_signal(new_sig));
			}
		}

		// ----------------------------------------
		// Remove drop port
		// ----------------------------------------
		cell->unsetPort(drop_port);

		log_debug("  Action     : drop port removed\n");
	}

	void transform_cell_with_ports(
		RTLIL::Cell *cell,
		RTLIL::IdString new_type,
		const pool<RTLIL::IdString> &allowed_ports)
	{
		// 1. Change cell type
		log("Changing cell %s type from %s to %s\n",
			log_id(cell), log_id(cell->type), log_id(new_type));

		cell->type = new_type;

		// 2. Remove ports not in allowed list
		vector<RTLIL::IdString> ports_to_remove;
		for (auto &it : cell->connections()) {
			if (!allowed_ports.count(it.first))
				ports_to_remove.push_back(it.first);
		}

		for (auto &p : ports_to_remove) {
			log_debug("Removing port %s from cell %s\n",
				log_id(p), log_id(cell));
			cell->unsetPort(p);
		}
	}

	void make_gnd_bits_unconn(RTLIL::Module *module,
                          RTLIL::Cell *cell,
                          const pool<RTLIL::IdString> &ports)
	{
		SigMap sigmap(module);

		log_debug("Processing cell %s (%s)\n",
			log_id(cell->name), log_id(cell->type));

		for (auto pname : ports)
		{
			if (!cell->hasPort(pname))
				continue;

			RTLIL::SigSpec sig = cell->getPort(pname);
			RTLIL::SigSpec new_sig;

			bool changed = false;

			log_debug("  Port %s: %s\n", log_id(pname), log_signal(sig));

			for (int i = 0; i < sig.size(); i++)
			{
				RTLIL::SigBit bit = sig[i];

				if (sigmap(bit) == RTLIL::State::S0)
				{
					log_debug("    bit %d -> GND replaced with \\unconn\n", i);
					new_sig.append(SigSpec());
					changed = true;
				}
				else
				{
					new_sig.append(bit);
				}
			}

			if (changed)
			{
				log_debug("  Updated port %s: %s\n",
					log_id(pname), log_signal(new_sig));

				cell->setPort(pname, new_sig);
			}
		}
	}

	// ============================================================================
	// Shared types
	// ============================================================================

	struct DSPUsage {
		RTLIL::Cell    *cell;
		RTLIL::IdString port;
		int             bit_idx;
	};

	// ============================================================================
	// Return true if cell is strictly a dffre (not sdffre, dff, dffn, etc.)
	// ============================================================================
	static bool is_dffre(const RTLIL::Cell *cell)
	{
		const std::string &t = cell->type.str();
		// must contain "dffre" but must NOT contain "sdffre" or "SDFFRE"
		if (t.find("sdffre") != std::string::npos) return false;
		if (t.find("SDFFRE") != std::string::npos) return false;
		return t.find("dffre")  != std::string::npos ||
			t.find("DFFRE")  != std::string::npos;
	}

	// ============================================================================
	// Collect all DSP input usages, grouped by canonical signal bit.
	// Pass an empty port filter to collect all input ports.
	// ============================================================================
	static dict<RTLIL::SigBit, std::vector<DSPUsage>>
	collect_dsp_usages(RTLIL::Module *module,
					const pool<RTLIL::IdString> &port_filter = {})
	{
		SigMap sigmap(module);
		dict<RTLIL::SigBit, std::vector<DSPUsage>> usage_map;

		log_debug("=== collect_dsp_usages START (filter size=%d) ===\n",
			GetSize(port_filter));

		for (auto cell : module->cells()) {
			if (cell->type.str().find("QL_DSPV2") == std::string::npos)
				continue;

			log_debug("  DSP cell=%s\n", log_id(cell));

			for (auto &conn : cell->connections()) {
				RTLIL::IdString port = conn.first;

				if (!cell->input(port)) {
					log_debug("    port=%s skip (not input)\n", log_id(port));
					continue;
				}
				if (!port_filter.empty() && !port_filter.count(port)) {
					log_debug("    port=%s skip (not in filter)\n", log_id(port));
					continue;
				}

				SigSpec sig = sigmap(conn.second);
				log_debug("    port=%s width=%d\n", log_id(port), GetSize(sig));

				for (int i = 0; i < GetSize(sig); i++) {
					SigBit bit = sigmap(sig[i]);
					if (bit.wire == nullptr) {
						log_debug("      bit[%d] skip (constant)\n", i);
						continue;
					}
					usage_map[bit].push_back({cell, port, i});
					log_debug("      bit[%d]=%s -> recorded (total usages=%d)\n",
						i, log_signal(bit), GetSize(usage_map[bit]));
				}
			}
		}

		log_debug("=== collect_dsp_usages END total_bits=%d ===\n\n",
			GetSize(usage_map));
		return usage_map;
	}

	// ============================================================================
	// Return true if bit is the output of a buffer cell (prevents double-buffering)
	// ============================================================================
	static bool is_buffer_output(RTLIL::Module *module, const RTLIL::SigBit &bit)
	{
		if (bit.wire == nullptr)
			return false;

		SigMap sigmap(module);
		for (auto cell : module->cells()) {
			if (cell->type != ID(buffer) || !cell->hasPort(ID(out)))
				continue;
			for (auto b : sigmap(cell->getPort(ID(out)))) {
				if (sigmap(b) == sigmap(bit)) {
					log_debug("  is_buffer_output: bit=%s already buffered by cell=%s\n",
						log_signal(bit), log_id(cell));
					return true;
				}
			}
		}
		return false;
	}

	// ============================================================================
	// Return true if bit comes from a dffre Q output (strict: not sdffre etc.)
	// Fills ff_cell and q_idx on success.
	// ============================================================================
	static bool get_dffre_q_driver(RTLIL::Module *module,
									const RTLIL::SigBit &bit,
									RTLIL::Cell *&ff_cell,
									int &q_idx)
	{
		if (bit.wire == nullptr) {
			log_debug("  get_dffre_q_driver: bit has no wire, skip\n");
			return false;
		}

		SigMap sigmap(module);
		for (auto cell : module->cells()) {
			if (!is_dffre(cell))
				continue;
			if (!cell->hasPort(ID::Q))
				continue;

			SigSpec qsig = sigmap(cell->getPort(ID::Q));
			for (int i = 0; i < GetSize(qsig); i++) {
				if (sigmap(qsig[i]) == sigmap(bit)) {
					ff_cell = cell;
					q_idx   = i;
					log_debug("  get_dffre_q_driver: bit=%s -> FF=%s Q[%d]\n",
						log_signal(bit), log_id(cell), i);
					return true;
				}
			}
		}

		log_debug("  get_dffre_q_driver: bit=%s -> no dffre driver found\n",
			log_signal(bit));
		return false;
	}

	// ============================================================================
	// Duplicate a dffre, overriding Q[q_idx] with a fresh wire.
	// Returns the new Q bit.
	// ============================================================================
	static RTLIL::SigBit duplicate_ff_bit(RTLIL::Module *module,
										RTLIL::Cell   *orig_ff,
										int            q_idx)
	{
		log_assert(orig_ff != nullptr);
		log_assert(is_dffre(orig_ff));

		SigSpec qsig = orig_ff->getPort("\\Q");
		if (q_idx >= GetSize(qsig))
			log_error("duplicate_ff_bit: q_idx=%d out of range (Q width=%d)\n",
				q_idx, GetSize(qsig));

		RTLIL::Wire *new_q = module->addWire(
			module->uniquify(stringf("\\%s_dup_q_%d",
				log_id(orig_ff), q_idx)),
			1);

		log_debug("  duplicate_ff_bit: orig_ff=%s q_idx=%d new_wire=%s\n",
			log_id(orig_ff), q_idx, log_id(new_q));

		RTLIL::Cell *dup_ff = module->addCell(
			module->uniquify(IdString("\\dffre")),
			IdString("\\dffre"));

		dup_ff->setPort("\\D", orig_ff->getPort("\\D"));
		dup_ff->setPort("\\C", orig_ff->getPort("\\C"));
		dup_ff->setPort("\\R", orig_ff->getPort("\\R"));
		dup_ff->setPort("\\E", orig_ff->hasPort("\\E")
			? orig_ff->getPort("\\E")
			: SigSpec());
		dup_ff->setPort("\\Q", SigSpec(new_q));

		log_debug("  created dup_ff=%s Q=%s\n", log_id(dup_ff), log_id(new_q));

		return SigBit(new_q);
	}

	// ============================================================================
	// Problem 1 — Insert a shared dummy buffer when a bit drives the same
	// bit index of port "a" on multiple DSPs, and is not dffre-driven.
	//
	//   src_bit --> buffer --> buf_wire --> all DSP a[i] sinks at same bit index
	// ============================================================================
	static void insert_dummy_buffer(
		RTLIL::Module *module,
		const RTLIL::SigBit &src_bit,
		const DSPUsage &usage)
	{
		static int buf_count = 0;
		std::string idx = stringf("%d", buf_count++);

		log_debug("  insert_dummy_buffer: src_bit=%s DSP=%s port=%s bit[%d] buf_idx=%s\n",
			log_signal(src_bit), log_id(usage.cell), log_id(usage.port),
			usage.bit_idx, idx.c_str());

		RTLIL::Wire *buf_wire = module->addWire(
			module->uniquify("\\dummy_buf_wire_" + idx));
		RTLIL::Cell *buf = module->addCell(
			module->uniquify("\\dummy_buf_" + idx), ID(buffer));

		buf->setPort(ID(in),  SigSpec(src_bit));
		buf->setPort(ID(out), SigSpec(buf_wire));

		log_debug("    buffer cell=%s wire=%s\n", log_id(buf), log_id(buf_wire));

		SigSpec sig = usage.cell->getPort(usage.port);
		sig[usage.bit_idx] = SigBit(buf_wire);
		usage.cell->setPort(usage.port, sig);

		log_debug("    rewire DSP=%s port=%s bit[%d] -> %s\n",
			log_id(usage.cell), log_id(usage.port), usage.bit_idx, log_id(buf_wire));
	}

	static void protect_shared_dsp_input(RTLIL::Module *module)
	{
		const RTLIL::IdString port_a = IdString("\\a");

		log_debug("=== protect_shared_dsp_input START ===\n");

		pool<RTLIL::IdString> filter = {port_a};
		auto usage_map = collect_dsp_usages(module, filter);

		pool<RTLIL::SigBit> processed;
		int buffered = 0;

		for (auto &it : usage_map) {
			SigBit bit    = it.first;
			auto  &usages = it.second;

			log_debug("  bit=%s usages=%d\n", log_signal(bit), GetSize(usages));

			if (GetSize(usages) <= 1) {
				log_debug("    skip (not shared)\n");
				continue;
			}
			if (is_buffer_output(module, bit)) {
				log_debug("    skip (already buffered)\n");
				continue;
			}
			if (processed.count(bit)) {
				log_debug("    skip (already processed)\n");
				continue;
			}

			// --------------------------------------------------------
			// Group by bit index — only insert buffers where the same
			// bit index is shared across multiple DSPs
			// --------------------------------------------------------
			dict<int, std::vector<DSPUsage>> by_bit_idx;
			for (auto &u : usages) {
				by_bit_idx[u.bit_idx].push_back(u);
				log_debug("    usage: DSP=%s port=%s bit[%d]\n",
					log_id(u.cell), log_id(u.port), u.bit_idx);
			}

			for (auto &bi : by_bit_idx) {
				int  bit_index        = bi.first;
				auto &same_idx_usages = bi.second;

				log_debug("    bit_index=%d shared_count=%d\n",
					bit_index, GetSize(same_idx_usages));

				if (GetSize(same_idx_usages) <= 1) {
					log_debug("      skip (only one DSP at this bit index)\n");
					continue;
				}

				// One buffer per DSP sink
				for (auto &u : same_idx_usages) {
					insert_dummy_buffer(module, bit, u);
					buffered++;
				}
			}

			processed.insert(bit);
		}

		log_debug("=== protect_shared_dsp_input END buffers_inserted=%d ===\n\n",
			buffered);
	}
	// ============================================================================
	// Problem 2 — Duplicate dffre when one bit drives multiple bit positions
	// of the SAME port (a, b, or c) on the SAME DSP.
	// ============================================================================
	static void duplicate_shared_dffres(RTLIL::Module *module,
										RTLIL::Cell   *target_cell,
										const pool<RTLIL::IdString> &input_ports)
	{
		SigMap sigmap(module);

		log_debug("=== duplicate_shared_dffres START cell=%s ===\n",
			log_id(target_cell));

		// Build dffre-only Q driver map
		dict<SigBit, RTLIL::Cell*> driver_map;
		for (auto cell : module->cells()) {
			if (!is_dffre(cell))       continue;
			if (!cell->hasPort(ID::Q)) continue;

			SigSpec qsig = sigmap(cell->getPort(ID::Q));
			log_debug("  FF candidate: cell=%s Q-width=%d\n",
				log_id(cell), GetSize(qsig));

			for (int i = 0; i < GetSize(qsig); i++) {
				SigBit bit = qsig[i];
				if (bit.wire) {
					driver_map[bit] = cell;
					log_debug("    driver_map: bit=%s -> FF=%s\n",
						log_signal(bit), log_id(cell));
				} else {
					log_debug("    bit[%d] skip (constant)\n", i);
				}
			}
		}
		log_debug("driver_map size=%d\n", GetSize(driver_map));

		for (auto port : input_ports) {
			if (!target_cell->hasPort(port)) {
				log_debug("SKIP port=%s (not present on cell=%s)\n",
					log_id(port), log_id(target_cell));
				continue;
			}

			SigSpec new_sig = target_cell->getPort(port);
			log_debug("\n--- port=%s width=%d ---\n", log_id(port), GetSize(new_sig));

			dict<RTLIL::Cell*, std::vector<int>> groups;
			for (int i = 0; i < GetSize(new_sig); i++) {
				SigBit b = sigmap(new_sig[i]);
				log_debug("  bit[%d]=%s", i, log_signal(b));

				if (b.wire == nullptr) {
					log_debug(" -> skip (constant)\n");
					continue;
				}
				if (!driver_map.count(b)) {
					log_debug(" -> no dffre driver\n");
					continue;
				}
				RTLIL::Cell *drv = driver_map[b];
				groups[drv].push_back(i);
				log_debug(" -> FF=%s (group size now %d)\n",
					log_id(drv), GetSize(groups[drv]));
			}

			log_debug("Groups before filtering:\n");
			for (auto &it : groups) {
				log_debug("  FF=%s bits=[", log_id(it.first));
				for (auto idx : it.second) log_debug(" %d", idx);
				log_debug(" ] size=%d\n", GetSize(it.second));
			}

			bool changed = false;
			for (auto &it : groups) {
				if (it.second.size() < 2) {
					log_debug("  SKIP singleton group FF=%s\n", log_id(it.first));
					continue;
				}

				RTLIL::Cell *drv  = it.first;
				auto        &idxs = it.second;

				SigSpec qsig       = sigmap(drv->getPort(ID::Q));
				SigBit  driven_bit = sigmap(new_sig[idxs[0]]);

				log_debug("  Resolving q_idx for FF=%s driven_bit=%s Q-width=%d\n",
					log_id(drv), log_signal(driven_bit), GetSize(qsig));

				int q_idx = -1;
				for (int i = 0; i < GetSize(qsig); i++) {
					SigBit qbit = sigmap(qsig[i]);
					log_debug("    Q[%d]=%s\n", i, log_signal(qbit));
					if (qbit == driven_bit) { q_idx = i; break; }
				}

				if (q_idx < 0) {
					log_debug("  ERROR: could not resolve q_idx for FF=%s bit=%s -- SKIP\n",
						log_id(drv), log_signal(driven_bit));
					continue;
				}

				log_debug("  q_idx=%d resolved OK\n", q_idx);
				log_debug("  Duplicating FF=%s for bit positions:", log_id(drv));
				for (auto i : idxs) log_debug(" %d", i);
				log_debug("\n");

				for (int k = 1; k < (int)idxs.size(); k++) {
					int    bit_index = idxs[k];
					SigBit new_q     = duplicate_ff_bit(module, drv, q_idx);
					new_sig[bit_index] = new_q;
					changed = true;
					log_debug("    bit[%d] -> new wire=%s\n",
						bit_index, log_signal(new_q));
				}
			}

			if (changed) {
				log_debug("Updating port=%s on cell=%s\n",
					log_id(port), log_id(target_cell));
				target_cell->setPort(port, new_sig);
			} else {
				log_debug("No changes for port=%s\n", log_id(port));
			}
		}

		log_debug("=== duplicate_shared_dffres END cell=%s ===\n\n",
			log_id(target_cell));
	}

	// ============================================================================
	// Problem 3 — Duplicate dffre when one bit drives:
	//   (a) multiple different DSP ports (a, b, c) across any DSPs, OR
	//   (b) any DSP port (a, b, c) AND any non-DSP cell.
	//
	// Result:
	//   - Each DSP gets its own dedicated register copy.
	//   - All non-DSP sinks share one register copy (the original or a duplicate).
	// ============================================================================
	static void duplicate_dffre_per_dsp_port(RTLIL::Module *module)
	{
		log_debug("=== duplicate_dffre_per_dsp_port START module=%s ===\n",
			log_id(module));

		SigMap sigmap(module);

		// Ports we care about on DSPs
		const pool<RTLIL::IdString> dsp_ports = {
			IdString("\\a"), IdString("\\b"), IdString("\\c")
		};

		// ----------------------------------------------------------------
		// Build dffre Q bit map: bit -> (ff_cell, q_idx)
		// ----------------------------------------------------------------
		dict<RTLIL::SigBit, std::pair<RTLIL::Cell*, int>> dffre_q_map;
		for (auto cell : module->cells()) {
			if (!is_dffre(cell))       continue;
			if (!cell->hasPort(ID::Q)) continue;
			SigSpec qsig = sigmap(cell->getPort(ID::Q));
			for (int i = 0; i < GetSize(qsig); i++) {
				SigBit bit = sigmap(qsig[i]);
				if (bit.wire) {
					dffre_q_map[bit] = {cell, i};
					log_debug("  dffre_q_map: bit=%s -> FF=%s Q[%d]\n",
						log_signal(bit), log_id(cell), i);
				}
			}
		}

		log_debug("  dffre_q_map size=%d\n", GetSize(dffre_q_map));

		// ----------------------------------------------------------------
		// For each dffre Q bit, collect DSP sinks (a/b/c only)
		// and non-DSP sinks
		// ----------------------------------------------------------------
		struct BitSinks {
			std::vector<DSPUsage>                                  dsp;
			std::vector<std::pair<RTLIL::Cell*, RTLIL::IdString>>  other;
		};

		dict<RTLIL::SigBit, BitSinks> sink_map;

		for (auto cell : module->cells()) {
			bool is_dsp = cell->type.str().find("QL_DSPV2") != std::string::npos;

			for (auto &conn : cell->connections()) {
				RTLIL::IdString port = conn.first;
				if (!cell->input(port)) continue;

				// For DSP cells restrict to ports a, b, c
				if (is_dsp && !dsp_ports.count(port)) continue;

				SigSpec sig = sigmap(conn.second);
				for (int i = 0; i < GetSize(sig); i++) {
					SigBit bit = sigmap(sig[i]);
					if (!dffre_q_map.count(bit)) continue;

					if (is_dsp) {
						sink_map[bit].dsp.push_back({cell, port, i});
						log_debug("  dsp sink: bit=%s DSP=%s port=%s bit[%d]\n",
							log_signal(bit), log_id(cell), log_id(port), i);
					} else {
						sink_map[bit].other.push_back({cell, port});
						log_debug("  other sink: bit=%s cell=%s port=%s\n",
							log_signal(bit), log_id(cell), log_id(port));
					}
				}
			}
		}

		int dup_total = 0;

		for (auto &it : sink_map) {
			SigBit      bit      = it.first;
			BitSinks   &sinks    = it.second;
			RTLIL::Cell *ff_cell = dffre_q_map[bit].first;
			int          q_idx   = dffre_q_map[bit].second;

			int dsp_count   = GetSize(sinks.dsp);
			int other_count = GetSize(sinks.other);

			log_debug("  bit=%s FF=%s Q[%d] dsp_sinks=%d other_sinks=%d\n",
				log_signal(bit), log_id(ff_cell), q_idx, dsp_count, other_count);

			if (dsp_count == 0) {
				log_debug("    skip (no DSP sinks)\n");
				continue;
			}

			if (dsp_count + other_count <= 1) {
				log_debug("    skip (single sink)\n");
				continue;
			}

			// --------------------------------------------------------
			// Group DSP sinks by port name only.
			// Same port on multiple DSPs is fine (buffers handle that),
			// only different ports need separate registers.
			// --------------------------------------------------------
			dict<RTLIL::IdString, std::vector<DSPUsage>> dsp_groups;
			for (auto &u : sinks.dsp) {
				dsp_groups[u.port].push_back(u);
				log_debug("    dsp usage: DSP=%s port=%s bit[%d]\n",
					log_id(u.cell), log_id(u.port), u.bit_idx);
			}

			for (auto &os : sinks.other)
				log_debug("    other usage: cell=%s port=%s\n",
					log_id(os.first), log_id(os.second));

			log_debug("    dsp_groups=%d other_sinks=%d\n",
				GetSize(dsp_groups), other_count);

			// --------------------------------------------------------
			// Nothing to do if only one DSP port group and no other sinks
			// --------------------------------------------------------
			if (GetSize(dsp_groups) == 1 && other_count == 0) {
				log_debug("    skip (single DSP port group, no other sinks)\n");
				continue;
			}

			// --------------------------------------------------------
			// Original FF keeps non-DSP sinks if any exist.
			// Otherwise original FF keeps first DSP port group.
			// Each remaining DSP port group gets its own duplicate.
			// --------------------------------------------------------
			bool original_used_for_other = (other_count > 0);

			if (original_used_for_other)
				log_debug("    original FF=%s kept for non-DSP sinks\n",
					log_id(ff_cell));

			bool first_dsp_group = true;
			for (auto &dg : dsp_groups) {
				RTLIL::IdString  dsp_port = dg.first;
				auto            &usages   = dg.second;

				// Keep original FF for first DSP group if no other sinks
				if (!original_used_for_other && first_dsp_group) {
					log_debug("    keep original FF=%s for port=%s (%d sinks)\n",
						log_id(ff_cell), log_id(dsp_port), GetSize(usages));
					first_dsp_group = false;
					continue;
				}

				log_debug("    duplicate FF=%s for port=%s (%d sinks)\n",
					log_id(ff_cell), log_id(dsp_port), GetSize(usages));

				SigBit new_q = duplicate_ff_bit(module, ff_cell, q_idx);
				dup_total++;

				for (auto &u : usages) {
					SigSpec sig = u.cell->getPort(u.port);
					if (u.bit_idx >= GetSize(sig))
						log_error("duplicate_dffre_per_dsp_port: bit_idx=%d out of range (port width=%d)\n",
							u.bit_idx, GetSize(sig));
					sig[u.bit_idx] = new_q;
					u.cell->setPort(u.port, sig);
					log_debug("      rewire DSP=%s port=%s bit[%d] -> %s\n",
						log_id(u.cell), log_id(u.port), u.bit_idx,
						log_signal(new_q));
				}

				first_dsp_group = false;
			}
		}

		log_debug("=== duplicate_dffre_per_dsp_port END duplications=%d ===\n\n",
			dup_total);
	}

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing QL_DSPV2_TYPES pass.\n");
		
		for (RTLIL::Module* module : design->selected_modules()){
			// Snapshot DSP cells before any modification
			std::vector<RTLIL::Cell*> dsp_cells;
			for (auto cell : module->cells()) {
				if (cell->type.str().find("QL_DSPV2") != std::string::npos)
					dsp_cells.push_back(cell);
			}


			// Problem 2 — one FF bit driving multiple positions of same port (a, b, c)
			const pool<RTLIL::IdString> abc_ports = {
				IdString("\\a"), IdString("\\b"), IdString("\\c")
			};
			for (auto cell : dsp_cells)
				duplicate_shared_dffres(module, cell, abc_ports);

			// Problem 3 — cross-port and cross-cell fanout
			duplicate_dffre_per_dsp_port(module);

			// Problem 1 — buffers on port a only, same bit index only
			protect_shared_dsp_input(module);

			for (RTLIL::Cell* cell: module->selected_cells())
			{
				if (cell->type != ID(QL_DSPV2) || !cell->hasParam(ID(MODE_BITS)))
					continue;

				RTLIL::Const mode_bits = cell->getParam(ID(MODE_BITS));

                int COEFF_0    = mode_bits.extract(0, 31).as_int();
				log_debug("COEFF_0: %d.\n", COEFF_0);
                int ACC_FIR    = mode_bits.extract(32, 6).as_int();
				log_debug("ACC_FIR: %d.\n", ACC_FIR);
                int ROUND      = mode_bits.extract(38, 3).as_int();
				log_debug("ROUND: %d.\n", ROUND);
                int ZC_SHIFT   = mode_bits.extract(41, 5).as_int();
				log_debug("ZC_SHIFT: %d.\n", ZC_SHIFT);
                int ZREG_SHIFT = mode_bits.extract(46, 5).as_int();
				log_debug("ZREG_SHIFT: %d.\n", ZREG_SHIFT);
                int SHIFT_REG  = mode_bits.extract(51, 6).as_int();
				log_debug("SHIFT_REG: %d.\n", SHIFT_REG);
                
                bool SATURATE  = mode_bits.extract(57).as_bool();
				if (SATURATE)
					log_debug("STARUATE Enabled.\n");
                bool SUBTRACT  = mode_bits.extract(58).as_bool();
				if (SUBTRACT)
					log_debug("SUBTRACT Enabled.\n");
                bool PRE_ADD   = mode_bits.extract(59).as_bool();
                if (PRE_ADD)
					log_debug("PRE_ADD Enabled.\n");
                bool A_SEL     = mode_bits.extract(60).as_bool();
				if (A_SEL)
					log_debug("A_SEL Enabled.\n");
                bool A_REG     = mode_bits.extract(61).as_bool();
				if (A_REG)
					log_debug("A_REG Enabled.\n");
                bool A1_REG    = mode_bits.extract(62).as_bool();
				if (A1_REG)
					log_debug("A1_REG Enabled.\n");
                bool A2_REG    = mode_bits.extract(63).as_bool();
				if (A2_REG)
					log_debug("A2_REG Enabled.\n");

                bool B_SEL     = mode_bits.extract(64).as_bool();
				if (B_SEL)
					log_debug("B_SEL Enabled.\n");
                bool B_REG     = mode_bits.extract(65).as_bool();
				if (B_REG)
					log_debug("B_REG Enabled.\n");
                bool B1_REG    = mode_bits.extract(66).as_bool();
				if (B1_REG)
					log_debug("B1_REG Enabled.\n");
                bool B2_REG    = mode_bits.extract(67).as_bool();	
				if (B2_REG)
					log_debug("B2_REG Enabled.\n");

                bool C_REG     = mode_bits.extract(68).as_bool();
				if (C_REG)
					log_debug("C_REG Enabled.\n");
                bool BC_REG    = mode_bits.extract(69).as_bool();
				if (BC_REG)
					log_debug("BC_REG Enabled.\n");
                bool M_REG     = mode_bits.extract(70).as_bool();
				if (M_REG)
					log_debug("M_REG Enabled.\n");
                bool ZCIN_SEL  = mode_bits.extract(71).as_bool();
				if (ZCIN_SEL)
					log_debug("ZCIN_SEL Enabled.\n");
                bool ACOUT_SEL = mode_bits.extract(72).as_bool();
				if (ACOUT_SEL)
					log_debug("ACOUT_SEL Enabled.\n");
                bool BCOUT_SEL = mode_bits.extract(73).as_bool();
				if (BCOUT_SEL)
					log_debug("BCOUT_SEL Enabled.\n");
                bool FRAC_MODE = mode_bits.extract(79).as_bool();
				if (FRAC_MODE)
					log_debug("FRAC_MODE Enabled.\n");

				int FEEDBACK = get_const_port_value(cell, ID(feedback));
				log_debug("FEEDBACK: %d.\n", FEEDBACK);
				int OUTPUT_SELECT = get_const_port_value(cell, ID(output_select));
				log_debug("OUTPUT_SELECT: %d.\n", OUTPUT_SELECT);

				replace_drop_net_with_keep_net(
					module,
					cell,
					RTLIL::IdString("\\z"),
					RTLIL::IdString("\\z_cout")
				);
				
				if (A1_REG && A2_REG) {
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\a")
						);
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\a")
						);
				}

				else if (A2_REG || A_REG) {
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\a")
						);
				}

				if (B1_REG && B2_REG) {
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\b")
						);
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\b")
						);
				}			
				else if (B2_REG || B_REG) {
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\b")
						);
				}
				if (C_REG) {
					add_bitwise_dffre_before_cell_input(
							module,
							cell,
							RTLIL::IdString("\\c")
						);
				}
				if (OUTPUT_SELECT >= 4)
					add_bitwise_dffre_after_cell_output(
						module,
						cell,
						RTLIL::IdString("\\z")
					);

				uint32_t control_word = get_control_word(FEEDBACK,
														 OUTPUT_SELECT,
														 ZCIN_SEL,
														 PRE_ADD,
														 SUBTRACT);
				

				log_debug("Control Word: %d\n", control_word);
				std::string type = "QL_DSPV2";
				switch (control_word){
					case 0b00000000: //MULT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(feedback),
														ID(output_select)
													});
						break;
					
						case 0b01011000: //CONCAT_CASCADE									
						case 0b01010000: //CONCAT_CASCADE
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CONCAT_CASCADE"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					

					case 0b00001000: //MULTACC
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(acc_reset),
														ID(load_acc),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					

					case 0b00001001: //MULTACC_NEG
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_NEG"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(acc_reset),
														ID(load_acc),
														ID(feedback),
														ID(output_select)
													});
						break;
					

					case 0b00000010: //PREADDER_MULT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_MULT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					
					case 0b01111110: //PREADDER_MULTADD
					case 0b01110110: //PREADDER_MULTADD
						make_gnd_bits_unconn(
											module,
											cell,
											pool<RTLIL::IdString>{ 
												ID(z_cin),
											});
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_MULTADD"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(feedback),
														ID(output_select),
														ID(z),
														ID(z_cin)
													});
						break;

					case 0b01111100: //MULTADD
					case 0b01110100: //MULTADD
						make_gnd_bits_unconn(
											module,
											cell,
											pool<RTLIL::IdString>{ 
												ID(z_cin),
											});
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(z_cin),
														ID(feedback),
														ID(output_select)
													});
						break;

					case 0b01111101: //MULTADD_NEG
					case 0b01110101: //MULTADD_NEG
						make_gnd_bits_unconn(
											module,
											cell,
											pool<RTLIL::IdString>{ 
												ID(z_cin),
											});
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_NEG"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(z_cin),
														ID(feedback),
														ID(output_select)
													});
						break;

					default:
						make_gnd_bits_unconn(
											module,
											cell,
											pool<RTLIL::IdString>{ 
												ID(z_cin),
											});
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2"),
												 pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(clk),
														ID(feedback),
														ID(load_acc),
														ID(output_select),
														ID(reset),
														ID(acc_reset),
														ID(z_cin),
														ID(z)
													});
						break;

				}
			}
		}
	}


} QlDSPV2TypesPass;

PRIVATE_NAMESPACE_END