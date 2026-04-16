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

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing QL_DSPV2_TYPES pass.\n");

		size_t argidx = 1;
		extra_args(args, argidx, design);

		for (RTLIL::Module* module : design->selected_modules()){
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

					case 0b01111100: //MULTADD
					case 0b01110100: //MULTADD
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