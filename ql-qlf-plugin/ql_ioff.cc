#include "kernel/log.h"
#include "kernel/modtools.h"
#include "kernel/register.h"
#include "kernel/rtlil.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// A boundary register that passed classification, awaiting the promotion
// decision. Keyed by cell: a Q that aliases several top-level output bits is one
// candidate with several slots, not one candidate per bit.
struct Candidate {
	RTLIL::Cell *cell = nullptr;
	bool is_input = false;                      // input IOFF vs output IOFF
	bool resetless = false;                     // R was constant 1
	RTLIL::SigBit r_bit;                        // valid only when !resetless
	std::vector<std::pair<RTLIL::Wire *, int>> slots; // output-IOFF bit positions
	bool accepted = true;
};

// The cell type a candidate is promoted to. This four-way mapping used to be
// duplicated verbatim in the input and output paths.
static RTLIL::IdString target_type(RTLIL::IdString src_type, bool resetless)
{
	bool negedge = src_type.in(ID(dffnre), ID(sdffnre));
	if (resetless)
		return negedge ? ID(dffn) : ID(dff);
	return negedge ? ID(io_sdffnr) : ID(io_sdffr);
}

// Returns the dedicated polarity inverter driving `bit`, or nullptr when `bit`
// needs no *added* inversion to reach an active-low reset pin.
//
// dfflegalize normalizes every reset to active-low before ql_ioff runs, so by
// the time this pass sees the netlist an active-high reset taken straight from a
// port appears as a dedicated 1-input inverting $lut, while an active-high reset
// computed in the fabric has had its inversion absorbed into the user's own
// reset-expression LUT -- where it costs nothing. Declining only the former is
// therefore cost-exact, not an approximation.
//
// Keying on WIDTH == 1 rather than "driver is a LUT" or "driver is not a port"
// matters: an active-low and an active-high fabric-derived reset are
// structurally identical apart from the LUT mask, and both must promote.
static RTLIL::Cell *dedicated_inverter_driving(ModWalker &modwalker, RTLIL::SigBit bit)
{
	pool<ModWalker::PortBit> drivers;
	modwalker.get_drivers(drivers, modwalker.sigmap(bit));
	if (GetSize(drivers) != 1)
		return nullptr; // top-level port, constant, or multiply driven -- fail open

	RTLIL::Cell *driver = drivers.begin()->cell;

	if (driver->type == ID($lut)) {
		if (driver->getParam(ID::WIDTH).as_int() != 1)
			return nullptr; // wider LUT -- the inversion is absorbed, so free
		RTLIL::Const lut = driver->getParam(ID::LUT);
		if (GetSize(lut) < 2)
			return nullptr; // malformed -- fail open
		// 1-input truth table: lut[0] = f(0), lut[1] = f(1). An inverter is
		// (1, 0). A buffer is (0, 1) and must not match.
		if (lut[0] == RTLIL::State::S1 && lut[1] == RTLIL::State::S0)
			return driver;
		return nullptr;
	}

	// Defensive: abc9 skipped, or -no_abc_opt.
	if (driver->type.in(ID($_NOT_), ID($not)))
		return driver;

	return nullptr;
}

struct QlIoffPass : public Pass {
	QlIoffPass() : Pass("ql_ioff", "Infer I/O FFs for qlf_k6n10f architecture") {}

	void help() override
	{
		//   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
		log("\n");
		log("    ql_ioff [selection]\n");
		log("\n");
		log("This pass promotes qlf_k6n10f registers directly connected to a top-level I/O\n");
		log("port to I/O FFs.\n");
		log("\n");
		log("A register with no reset is promoted to dff/dffn. A register with a used\n");
		log("synchronous reset is promoted to io_sdffr/io_sdffnr, the GPIO architecture v3.0\n");
		log("IO subtile flip-flops. Registers with an enable, or with an asynchronous reset,\n");
		log("are never promoted: the IO subtile FF has neither.\n");
		log("\n");
		log("The IO FF reset pin is active-low. A register whose reset would need a\n");
		log("dedicated inverter LUT to satisfy that -- an active-high reset taken straight\n");
		log("from a port -- is left in the CLB rather than putting a LUT and a routing hop\n");
		log("on the IO reset path. An inversion absorbed into a wider reset-expression LUT\n");
		log("is free and promotes normally.\n");
		log("\n");
		log("    -min_shared_reset <K>\n");
		log("        Override the polarity rule above when the inverter is shared. If K or\n");
		log("        more promotable candidates hang off the same inverter, its cost is\n");
		log("        amortized and the whole group is promoted. The decision is per reset\n");
		log("        group and all-or-nothing, and counts promotable candidates rather than\n");
		log("        raw net fan-out.\n");
		log("\n");
		log("        K=0 disables the override, so the polarity rule always applies. K=1\n");
		log("        (the default) promotes every group, making the polarity rule a no-op.\n");
		log("        K=n>=2 promotes only groups of n or more. A negative or non-numeric\n");
		log("        value is an error.\n");
		log("\n");
		log("Note io_sdffr/io_sdffnr require a GPIO v3.0 architecture. Emitting them into a\n");
		log("BLIF consumed by a v2.x architecture fails in packing with an unknown model.\n");
		log("\n");
	}

	bool replace_existing_pass() const override
	{
		return true;
	}

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing QL_IOFF pass.\n");

		// Threshold for the shared-inverter override. 0 disables it; 1 (the
		// default) promotes every group, making the polarity rule a no-op.
		int min_shared_reset = 1;

		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			if (args[argidx] == "-min_shared_reset" && argidx + 1 < args.size()) {
				std::string value = args[++argidx];
				// Digit-scan rather than atoi, which silently yields 0 for
				// garbage. Clamping would be worse still: this knob exists to
				// be swept from scripts, so a bad value has to be loud.
				if (value.find_first_not_of("0123456789") != std::string::npos)
					log_error("ql_ioff: -min_shared_reset expects a non-negative integer, "
						  "got '%s'.\n",
						  value.c_str());
				min_shared_reset = std::stoi(value);
				continue;
			}
			break;
		}
		// Mandatory, and the reason is typo detection rather than [selection]
		// support: extra_args is what rejects an unrecognized option. Without
		// it, `ql_ioff -min_shared_rest 2` runs silently at K=0 and yields a
		// sweep row that looks like data but is not.
		extra_args(args, argidx, design);

		ModWalker modwalker(design);
		Module *module = design->top_module();
		if (!module)
			return;
		modwalker.setup(module);

		dict<SigBit, pool<SigBit>> output_bit_aliases;
		for (Wire *wire : module->wires())
			if (wire->port_output)
				for (SigBit bit : SigSpec(wire))
					output_bit_aliases[modwalker.sigmap(bit)].insert(bit);

		// --- Phase 1: classify ------------------------------------------------
		//
		// Same traversal and eligibility tests as before, but the combined
		// `E && R` constant check is split so that a used reset no longer
		// disqualifies a candidate, and the refusal reasons are separable.
		std::vector<Candidate> candidates;
		int declined_enable = 0;
		int declined_async = 0;
		int declined_dfanout = 0;

		for (auto cell : module->selected_cells()) {
			if (!cell->type.in(ID(dffre), ID(sdffre), ID(dffnre), ID(sdffnre)))
				continue;

			log_debug("Checking cell %s.\n", cell->name.c_str());
			bool e_const = cell->getPort(ID::E).is_fully_ones();
			bool r_const = cell->getPort(ID::R).is_fully_ones();

			if (!e_const) {
				// The IO subtile FF has no enable.
				log_debug("not promoting %s: E is used\n", log_id(cell));
				declined_enable++;
				continue;
			}

			bool is_sync = cell->type.in(ID(sdffre), ID(sdffnre));
			if (!r_const && !is_sync) {
				// The IO subtile FF reset is synchronous only.
				log_debug("not promoting %s: asynchronous reset is used\n", log_id(cell));
				declined_async++;
				continue;
			}

			Candidate cand;
			cand.cell = cell;
			cand.resetless = r_const;
			if (!r_const) {
				SigSpec r = cell->getPort(ID::R);
				log_assert(GetSize(r) == 1);
				cand.r_bit = modwalker.sigmap(r[0]);
			}

			SigSpec d = cell->getPort(ID::D);
			log_assert(GetSize(d) == 1);
			if (modwalker.has_inputs(d) && !modwalker.has_outputs(d)) {
				log_debug("Cell %s is potentially eligible for promotion to input IOFF.\n", cell->name.c_str());
				// check that d_sig has no other consumers
				pool<ModWalker::PortBit> portbits;
				modwalker.get_consumers(portbits, d);
				if (GetSize(portbits) > 1) {
					log_debug("not promoting %s: D has other consumers\n", log_id(cell));
					declined_dfanout++;
					continue;
				}
				cand.is_input = true;
				candidates.push_back(cand);
				continue; // prefer input FFs over output FFs
			}

			SigSpec q = cell->getPort(ID::Q);
			log_assert(GetSize(q) == 1);
			if (modwalker.has_outputs(q) && !modwalker.has_consumers(q)) {
				log_debug("Cell %s is potentially eligible for promotion to output IOFF.\n", cell->name.c_str());
				cand.is_input = false;
				for (SigBit bit : output_bit_aliases[modwalker.sigmap(q)]) {
					log_assert(bit.is_wire());
					cand.slots.emplace_back(bit.wire, bit.offset);
				}
				if (!cand.slots.empty())
					candidates.push_back(cand);
			}
		}

		// --- Phase 2: group by reset net, then decide -------------------------
		//
		// "How many other promotable candidates share this register's polarity
		// inverter?" is not answerable per cell, which is why the decision needs
		// its own phase between classification and mutation.
		dict<SigBit, std::vector<Candidate *>> groups;
		std::vector<std::pair<SigBit, int>> declined_groups;

		for (auto &cand : candidates) {
			if (cand.resetless)
				continue; // no reset polarity to satisfy
			if (!dedicated_inverter_driving(modwalker, cand.r_bit))
				continue; // no inverter, or the inversion is free
			groups[cand.r_bit].push_back(&cand);
		}

		for (auto &group_it : groups) {
			std::vector<Candidate *> &group = group_it.second;
			// The count is of promotable candidates, not raw net fan-out: only
			// candidates benefit from promotion, so only they can justify
			// amortizing the inverter. All-or-nothing, because the cost being
			// weighed is shared and a per-register decision cannot see it.
			bool override_ok = min_shared_reset >= 1 && GetSize(group) >= min_shared_reset;

			for (auto *cand : group) {
				cand->accepted = override_ok;
				if (!override_ok)
					log_debug("not promoting %s: reset polarity requires inversion\n", log_id(cand->cell));
			}

			if (override_ok) {
				log("Promoting %d register(s) sharing reset %s despite the polarity inverter "
				    "(%d >= K=%d).\n",
				    GetSize(group), log_signal(group_it.first), GetSize(group), min_shared_reset);
			} else {
				declined_groups.emplace_back(group_it.first, GetSize(group));
				// One warning per group, not per register: the actionable unit
				// is the reset net, since the fix is a single RTL edit at its
				// declaration. The group size doubles as the exact threshold
				// that would flip this decision.
				log_warning("Not promoting %d register(s) with reset %s to IO FFs: the reset is "
					    "active-high, so an inverter LUT would sit on the IO reset path. Use an "
					    "active-low reset, or pass -min_shared_reset %d (or lower) to accept the "
					    "inverter.\n",
					    GetSize(group), log_signal(group_it.first), GetSize(group));
			}
		}

		// --- Phase 3: apply --------------------------------------------------
		dict<IdString, int> promoted;
		promoted[ID(dff)] = 0;
		promoted[ID(dffn)] = 0;
		promoted[ID(io_sdffr)] = 0;
		promoted[ID(io_sdffnr)] = 0;

		for (auto &cand : candidates) {
			if (!cand.accepted || !cand.is_input)
				continue;

			Cell *cell = cand.cell;
			IdString new_type = target_type(cell->type, cand.resetless);
			log("Promoting register %s to input IOFF (%s).\n", log_signal(cell->getPort(ID::Q)), log_id(new_type));
			promoted[new_type]++;
			cell->type = new_type;
			cell->unsetPort(ID::E);
			if (cand.resetless)
				cell->unsetPort(ID::R);
			// Otherwise R and its connection are preserved as they are.
		}

		dict<Wire *, dict<int, Candidate *>> accepted_slots;
		for (auto &cand : candidates) {
			if (!cand.accepted || cand.is_input)
				continue;
			for (auto &slot : cand.slots)
				accepted_slots[slot.first][slot.second] = &cand;
		}

		// Walk the port outputs in module order rather than in candidate
		// discovery order, so the replacement wires are created in the same
		// sequence as before this pass was restructured. Otherwise a design with
		// two promoted output ports would get its NEW_ID wire names allocated in
		// a different order -- a gratuitous netlist diff.
		dict<Wire *, std::vector<Candidate *>> output_ffs;
		for (Wire *wire : module->wires()) {
			if (!wire->port_output || !accepted_slots.count(wire))
				continue;
			std::vector<Candidate *> slots(wire->width, nullptr);
			for (auto &it : accepted_slots.at(wire))
				slots[it.first] = it.second;
			output_ffs[wire] = slots;
		}

		for (auto &[old_port_output, ioff_cells] : output_ffs) {
			// create replacement output wire
			RTLIL::Wire *new_port_output = module->addWire(NEW_ID, old_port_output->width);
			new_port_output->start_offset = old_port_output->start_offset;
			module->swap_names(old_port_output, new_port_output);
			std::swap(old_port_output->port_id, new_port_output->port_id);
			std::swap(old_port_output->port_input, new_port_output->port_input);
			std::swap(old_port_output->port_output, new_port_output->port_output);
			std::swap(old_port_output->upto, new_port_output->upto);
			std::swap(old_port_output->is_signed, new_port_output->is_signed);
			std::swap(old_port_output->attributes, new_port_output->attributes);

			// create new output FFs
			SigSpec sig_o(old_port_output);
			SigSpec sig_n(new_port_output);
			for (int i = 0; i < new_port_output->width; i++) {
				Candidate *cand = ioff_cells[i];
				if (!cand) {
					module->connect(sig_n[i], sig_o[i]);
					continue;
				}

				Cell *src = cand->cell;
				IdString new_type = target_type(src->type, cand->resetless);
				log("Promoting %s to output IOFF (%s).\n", log_signal(sig_n[i]), log_id(new_type));

				promoted[new_type]++;
				RTLIL::Cell *new_cell = module->addCell(NEW_ID, new_type);
				log_assert(new_cell != nullptr);
				new_cell->setPort(ID::C, src->getPort(ID::C));
				new_cell->setPort(ID::D, src->getPort(ID::D));
				new_cell->setPort(ID::Q, sig_n[i]);
				if (!cand->resetless)
					new_cell->setPort(ID::R, src->getPort(ID::R));
				new_cell->set_bool_attribute(ID::keep);
			}
		}

		// --- Phase 4: summary -------------------------------------------------
		//
		// On the normal log, so that a K sweep produces diffable output. The
		// per-group candidate counts are the load-bearing part: totals alone say
		// which K won, the group sizes say which K would have changed anything.
		int total_promoted = 0;
		for (auto &it : promoted)
			total_promoted += it.second;

		int declined_polarity = 0;
		for (auto &it : declined_groups)
			declined_polarity += it.second;

		log("ql_ioff summary: K=%d\n", min_shared_reset);
		log("  promoted: dff=%d dffn=%d io_sdffr=%d io_sdffnr=%d   (total %d)\n", promoted[ID(dff)],
		    promoted[ID(dffn)], promoted[ID(io_sdffr)], promoted[ID(io_sdffnr)], total_promoted);
		log("  declined by reset polarity: %d in %d group(s)\n", declined_polarity, GetSize(declined_groups));
		for (auto &it : declined_groups)
			log("    reset %s : %d candidate(s)\n", log_signal(it.first), it.second);
		log("  declined other: E used=%d, async reset=%d, D has other consumers=%d\n", declined_enable,
		    declined_async, declined_dfanout);
	}
} QlIoffPass;

PRIVATE_NAMESPACE_END
