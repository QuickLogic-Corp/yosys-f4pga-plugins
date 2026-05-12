/*
 * Copyright 2020-2022 F4PGA Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 */

// Derived from YosysHQ/yosys PR #4932 (ql_dsp.cc by povik/widlarizer).
// Adapted for 80-bit MODE_BITS layout and plugin build system.
// Pass renamed to ql_dsp_dspv2 to avoid collision with the existing
// ql_dsp pass (which targets k6n10).

#include "kernel/rtlil.h"
#include "kernel/register.h"
#include "kernel/sigtools.h"

PRIVATE_NAMESPACE_BEGIN
USING_YOSYS_NAMESPACE

// promote dspv2_16x9x32_cfg_ports to dspv2_32x18x64_cfg_ports if need be
bool promote(Module *m, Cell *cell) {
	if (cell->type == ID(dspv2_32x18x64_cfg_ports)) {
		return false;
	} else {
		log_assert(cell->type == ID(dspv2_16x9x32_cfg_ports));
	}

	auto widen_output = [&](IdString port_name, int new_width) {
		if (!cell->hasPort(port_name))
			return;
		SigSpec port = cell->getPort(port_name);
		if (port.size() < new_width) {
			port = {m->addWire(NEW_ID, new_width - port.size()), port};
			cell->setPort(port_name, port);
		}
	};

	auto widen_input = [&](IdString port_name, int new_width) {
		if (!cell->hasPort(port_name))
			return;
		SigSpec port = cell->getPort(port_name);
		if (port.size() < new_width) {
			port.extend_u0(new_width, /* is_signed= */ true);
			cell->setPort(port_name, port);
		}
	};

	widen_output(ID(z_o), 50);
	widen_output(ID(a_cout_o), 32);
	widen_output(ID(b_cout_o), 18);
	widen_output(ID(z_cout_o), 50);

	auto uses_port = [&](IdString port_name) {
		return cell->hasPort(port_name) && !cell->getPort(port_name).is_fully_undef();
	};

	if (uses_port(ID(a_cin_i)) || uses_port(ID(b_cin_i)) || uses_port(ID(z_cin_i))) {
		log_error("Cannot promote %s (type %s) with cascading paths\n", log_id(cell), log_id(cell->type));
	}

	widen_input(ID(a_i), 32);
	widen_input(ID(b_i), 18);
	widen_input(ID(c_i), 18);
	cell->type = ID(dspv2_32x18x64_cfg_ports);
	return true;
}

bool did_something;

#include "pmgen/ql-dsp-dspv2-pm.h"

struct QlDspDspv2Pass : Pass {
	QlDspDspv2Pass() : Pass("ql_dsp_dspv2", "pack into QuickLogic DSPv2 blocks") {}

	void help() override
	{
		//   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
		log("\n");
		log("    ql_dsp_dspv2 [selection]\n");
		log("\n");
		log("This pass packs input and output path registers into QuickLogic DSPv2 blocks,\n");
		log("additionally it supports Z path cascading and post-adder packing.\n");
		log("\n");
		log("    -nocascade\n");
		log("        forbid cascading\n");
		log("\n");

	}

	void execute(std::vector<std::string> args, RTLIL::Design *d) override
	{
		log_header(d, "Executing QL_DSP_DSPV2 pass. (pack into QuickLogic DSPv2 blocks)\n");

		bool nocascade = false;
		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			if (args[argidx] == "-nocascade") {
				nocascade = true;
				continue;
			}
			break;
		}
		extra_args(args, argidx, d);

		for (auto module : d->selected_modules()) {
			did_something = true;

			while (did_something)
			{
				// TODO: could be optimized by more reuse of the pmgen object
				did_something = false;
				{
					ql_dsp_dspv2_pm pm(module, module->selected_cells());
					pm.run_ql_dsp_dspv2_pack_regs();
				}
				if (!nocascade) {
					ql_dsp_dspv2_pm pm(module, module->selected_cells());
					pm.run_ql_dsp_dspv2_cascade();
				}
				{
					ql_dsp_dspv2_pm pm(module, module->selected_cells());
					pm.run_ql_dsp_dspv2_pack_regs();
				}
			}
		}
	}
} QlDspDspv2Pass;

PRIVATE_NAMESPACE_END
