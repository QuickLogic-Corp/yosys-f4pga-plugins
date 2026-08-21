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
	std::vector<std::pair<RTLIL::Wire *, int>> slots; // output-IOFF bit positions
};

// The cell type a candidate is promoted to. This four-way mapping used to be
// duplicated verbatim in the input and output paths.
//
// `have_io_ff` says whether the cell library defines the GPIO v3.0 IO subtile FF,
// which decides where a *reset-less* candidate goes. v3.0 collapsed the two v2.x IO
// flip-flops into one whose synchronous reset is hard-wired to io.lreset with no
// mux, so those architectures declare no dff/dffn model at all and a plain dff is
// unpackable. Target the reset FF and hold its active-low reset inactive instead.
// v2.x libraries have no io_sdffr, and there dff/dffn still pack into io_ff/LATCH
// exactly as before.
static RTLIL::IdString target_type(RTLIL::IdString src_type, bool resetless, bool have_io_ff)
{
	bool negedge = src_type.in(ID(dffnre), ID(sdffnre));
	if (resetless && !have_io_ff)
		return negedge ? ID(dffn) : ID(dff);
	return negedge ? ID(io_sdffnr) : ID(io_sdffr);
}

// True for the two IO subtile FF types, whose R pin must be driven even when the
// register being promoted had no reset.
static bool is_io_ff(RTLIL::IdString type)
{
	return type.in(ID(io_sdffr), ID(io_sdffnr));
}

// Map VCC/GND driver-cell outputs to constant bits.
//
// Needed because the two front ends spell an unused control pin differently. On the
// Yosys path ffs_map.v ties E and R to a literal 1'b1, so a plain is_fully_ones()
// answers "is this pin unused?". Synplify instead drives them from a VCC cell's
// output net, which is electrically the same but structurally a wire -- so the
// literal test says "used" and every candidate would be refused. The DSP passes hit
// this first; mirrors ql_dspv2_types::build_const_drivers.
static void build_const_drivers(RTLIL::Module *module, SigMap &sigmap, dict<SigBit, State> &const_drivers)
{
	for (auto *drv : module->cells()) {
		if (drv->type == ID(VCC)) {
			for (auto &bit : sigmap(drv->getPort(ID(P))))
				const_drivers[bit] = State::S1;
		} else if (drv->type == ID(GND)) {
			for (auto &bit : sigmap(drv->getPort(ID(G))))
				const_drivers[bit] = State::S0;
		}
	}
}

// True when every bit of `port` is constant 1 once VCC/GND driver cells are resolved.
// Unlike ql_dspv2_types::get_const_port_value this returns a bool rather than
// erroring on a non-constant port: here a genuinely used enable or reset is ordinary
// input, not a malformed netlist.
static bool port_is_const_ones(RTLIL::Cell *cell, RTLIL::IdString port, SigMap &sigmap,
			       const dict<SigBit, State> &const_drivers)
{
	if (!cell->hasPort(port))
		return false;
	RTLIL::SigSpec sig = sigmap(cell->getPort(port));
	for (auto &bit : sig) {
		auto it = const_drivers.find(bit);
		if (it != const_drivers.end())
			bit = SigBit(it->second);
	}
	return sig.is_fully_ones();
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
		log("A register with a used synchronous reset is promoted to io_sdffr/io_sdffnr,\n");
		log("the GPIO architecture v3.0 IO subtile flip-flops. Registers with an enable, or\n");
		log("with an asynchronous reset, are never promoted: the IO subtile FF has neither.\n");
		log("\n");
		log("Reset polarity does not matter. The IO FF reset is active low, so an active-high\n");
		log("reset is inverted -- but a fabric sdffre resets on !R too, so that inverter exists\n");
		log("whether or not the register is promoted. Promoting costs only the route from it to\n");
		log("the IO site's local reset.\n");
		log("\n");
		log("A register with no reset goes to io_sdffr/io_sdffnr as well, with its active-low\n");
		log("reset tied to constant 1, whenever the cell library defines those primitives --\n");
		log("v3.0 has a single IO flip-flop whose reset is hard-wired, so it declares no\n");
		log("dff/dffn model and a plain dff cannot be packed. On a v2.x library, where the\n");
		log("primitives are absent, a reset-less register is promoted to dff/dffn as before.\n");
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

		size_t argidx = 1;
		extra_args(args, argidx, design);

		ModWalker modwalker(design);
		Module *module = design->top_module();
		if (!module)
			return;
		modwalker.setup(module);

		// Resolve VCC/GND driver cells to constants before any pin is inspected,
		// so the eligibility tests below read the same on both front ends.
		dict<SigBit, State> const_drivers;
		build_const_drivers(module, modwalker.sigmap, const_drivers);

		// GPIO v3.0 cell libraries define the IO subtile FF; v2.x ones do not, so
		// its presence in the design is the architecture-version signal. Keying on
		// the library rather than a pass option means the right thing happens per
		// device with nothing to set: the flow reads cells_sim.v from device_data,
		// which ships the primitives only on v3.0 devices. Both edges are required
		// because a reset-less candidate may need either.
		const bool have_io_ff = design->module(ID(io_sdffr)) && design->module(ID(io_sdffnr));

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
			bool e_const = port_is_const_ones(cell, ID::E, modwalker.sigmap, const_drivers);
			bool r_const = port_is_const_ones(cell, ID::R, modwalker.sigmap, const_drivers);

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

		// --- Phase 2: apply --------------------------------------------------
		dict<IdString, int> promoted;
		promoted[ID(dff)] = 0;
		promoted[ID(dffn)] = 0;
		promoted[ID(io_sdffr)] = 0;
		promoted[ID(io_sdffnr)] = 0;

		for (auto &cand : candidates) {
			if (!cand.is_input)
				continue;

			Cell *cell = cand.cell;
			IdString new_type = target_type(cell->type, cand.resetless, have_io_ff);
			log("Promoting register %s to input IOFF (%s).\n", log_signal(cell->getPort(ID::Q)), log_id(new_type));
			promoted[new_type]++;
			cell->type = new_type;
			cell->unsetPort(ID::E);
			if (cand.resetless) {
				// The IO subtile FF has no reset-less variant, so a reset-less
				// register keeps an R pin and holds it inactive. R is active low,
				// hence constant 1. dff/dffn have no R at all, so drop it there.
				if (is_io_ff(new_type))
					cell->setPort(ID::R, State::S1);
				else
					cell->unsetPort(ID::R);
			}
			// Otherwise R and its connection are preserved as they are.
		}

		dict<Wire *, dict<int, Candidate *>> output_slots;
		for (auto &cand : candidates) {
			if (cand.is_input)
				continue;
			for (auto &slot : cand.slots)
				output_slots[slot.first][slot.second] = &cand;
		}

		// Walk the port outputs in module order rather than in candidate
		// discovery order, so the replacement wires are created in the same
		// sequence as before this pass was restructured. Otherwise a design with
		// two promoted output ports would get its NEW_ID wire names allocated in
		// a different order -- a gratuitous netlist diff.
		dict<Wire *, std::vector<Candidate *>> output_ffs;
		for (Wire *wire : module->wires()) {
			if (!wire->port_output || !output_slots.count(wire))
				continue;
			std::vector<Candidate *> slots(wire->width, nullptr);
			for (auto &it : output_slots.at(wire))
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
				IdString new_type = target_type(src->type, cand->resetless, have_io_ff);
				log("Promoting %s to output IOFF (%s).\n", log_signal(sig_n[i]), log_id(new_type));

				promoted[new_type]++;
				RTLIL::Cell *new_cell = module->addCell(NEW_ID, new_type);
				log_assert(new_cell != nullptr);
				new_cell->setPort(ID::C, src->getPort(ID::C));
				new_cell->setPort(ID::D, src->getPort(ID::D));
				new_cell->setPort(ID::Q, sig_n[i]);
				if (!cand->resetless)
					new_cell->setPort(ID::R, src->getPort(ID::R));
				else if (is_io_ff(new_type))
					new_cell->setPort(ID::R, State::S1); // active low, held inactive
				new_cell->set_bool_attribute(ID::keep);
			}
		}

		// --- Phase 3: summary -------------------------------------------------
		//
		// On the normal log rather than log_debug, so a run is diffable and a zero
		// promotion count is visible rather than silent.
		int total_promoted = 0;
		for (auto &it : promoted)
			total_promoted += it.second;

		log("ql_ioff summary:\n");
		log("  promoted: dff=%d dffn=%d io_sdffr=%d io_sdffnr=%d   (total %d)\n", promoted[ID(dff)],
		    promoted[ID(dffn)], promoted[ID(io_sdffr)], promoted[ID(io_sdffnr)], total_promoted);
		log("  declined: E used=%d, async reset=%d, D has other consumers=%d\n", declined_enable,
		    declined_async, declined_dfanout);
	}
} QlIoffPass;

PRIVATE_NAMESPACE_END
