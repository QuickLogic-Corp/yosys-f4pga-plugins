#include "kernel/log.h"
#include "kernel/register.h"
#include "kernel/rtlil.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// Translate Synplify's inferred IO flip-flops onto the GPIO v3.0 IO subtile
// primitive.
//
// Synplify owns the decision about which boundary registers become IO flip-flops;
// this pass only re-spells that decision in the form the v3.0 architecture can
// hold. It is a strict one-for-one rewrite: no cell is created, deleted or
// skipped, so the set of registers Synplify chose is preserved exactly.
//
// Why a translation is needed at all. Synplify emits IBUF_FF/OBUF_FF, which
// synplify_map.v maps onto a plain `dff`. GPIO v3.0 collapsed the two v2.x IO
// flip-flops into one whose synchronous reset is hard-wired to io.lreset with no
// multiplexer, so those architectures declare no dff model and that `dff` cannot
// be packed. io_sdffr with its active-low reset tied to constant 1 is the same
// register, spelled in the only form the tile has.
//
// Why it consumes IBUF_FF/OBUF_FF directly rather than sweeping for `dff`. A
// sweep would also catch a `dff` a designer instantiated by hand in the fabric --
// cells_sim.v makes that a public primitive -- and relocating one of those into an
// IO-tile primitive would be both unpackable and a decision this pass has no
// business making. Consuming the cells at their source keeps the rewrite exact and
// makes the 1:1 count check trivially true by construction.

struct QlIoTranslatePass : public Pass {
	QlIoTranslatePass() : Pass("ql_io_translate", "Translate Synplify IO FFs to GPIO v3.0 IO FFs") {}

	void help() override
	{
		//   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
		log("\n");
		log("    ql_io_translate [selection]\n");
		log("\n");
		log("Rewrites the IBUF_FF/OBUF_FF cells Synplify infers into the GPIO architecture\n");
		log("v3.0 IO subtile flip-flop, io_sdffr, with its active-low reset tied to constant\n");
		log("1 so it never fires. Ports are remapped O->Q and I->D; C is unchanged.\n");
		log("\n");
		log("Which boundary registers are IO flip-flops is Synplify's decision. This pass\n");
		log("only changes how that decision is spelled, one cell in for one cell out, and\n");
		log("errors out if that ever stops being true.\n");
		log("\n");
		log("The pass is a no-op unless the cell library defines io_sdffr, which is the\n");
		log("signal that the target is a v3.0 architecture. On v2.x, IBUF_FF/OBUF_FF are\n");
		log("left alone for synplify_map.v to map to dff, which the v2.x io_ff/LATCH mode\n");
		log("still accepts.\n");
		log("\n");
		log("Both primitives are posedge-only and carry no reset, so the target is always\n");
		log("io_sdffr; io_sdffnr is unreachable from Synplify inference.\n");
		log("\n");
	}

	bool replace_existing_pass() const override
	{
		return true;
	}

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing QL_IO_TRANSLATE pass.\n");

		size_t argidx = 1;
		extra_args(args, argidx, design);

		// The per-device cells_sim.v ships io_sdffr only on v3.0 devices, so its
		// presence in the design is the architecture-version signal -- no pass
		// option and no arch parsing needed.
		const bool have_io_ff = design->module(ID(io_sdffr)) != nullptr;

		int consumed = 0;
		int produced = 0;
		int seen_without_target = 0;

		for (auto module : design->selected_modules()) {
			for (auto cell : module->selected_cells()) {
				if (!cell->type.in(ID(IBUF_FF), ID(OBUF_FF)))
					continue;

				if (!have_io_ff) {
					seen_without_target++;
					continue;
				}

				consumed++;

				RTLIL::SigSpec o = cell->getPort(ID(O));
				RTLIL::SigSpec i = cell->getPort(ID(I));
				RTLIL::SigSpec c = cell->getPort(ID(C));

				cell->unsetPort(ID(O));
				cell->unsetPort(ID(I));

				cell->type = ID(io_sdffr);
				cell->setPort(ID::Q, o);
				cell->setPort(ID::D, i);
				cell->setPort(ID::C, c);
				// Active low, so constant 1 is "never reset". The IO subtile FF has
				// no reset-less variant to target instead.
				cell->setPort(ID::R, RTLIL::State::S1);

				produced++;
			}
		}

		// Checked on the fly rather than from a before/after snapshot: the two
		// counters move together inside the rewrite, so they can only diverge if a
		// later edit introduces a skip or creates a cell -- which is exactly the
		// class of change that would silently alter Synplify's IO FF set.
		if (consumed != produced)
			log_error("ql_io_translate: consumed %d IBUF_FF/OBUF_FF cell(s) but produced %d IO FF(s). "
				  "Synplify's IO FF set must be translated one-for-one, never changed.\n",
				  consumed, produced);

		if (seen_without_target)
			log_warning("ql_io_translate: %d IBUF_FF/OBUF_FF cell(s) left untranslated because the cell "
				    "library does not define io_sdffr. That is expected on a v2.x architecture, where "
				    "they map to dff; on a v3.0 architecture it means the device is shipping the wrong "
				    "cell library and packing will fail with an unknown model.\n",
				    seen_without_target);

		log("ql_io_translate: %d IBUF_FF/OBUF_FF -> io_sdffr (reset tied inactive)\n", produced);
	}
} QlIoTranslatePass;

PRIVATE_NAMESPACE_END
