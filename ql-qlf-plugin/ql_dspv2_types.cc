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

		log("Cell %s %s = %s\n",
			log_id(cell), log_id(port_name), log_signal(sig));

		if (!sig.is_fully_const())
			log_error("Cell %s: port %s is not constant (%s)\n",
					log_id(cell), log_id(port_name), log_signal(sig));

		RTLIL::Const c = sig.as_const();
		int value = c.as_int();

		log("%s value: %d\n", log_id(port_name), value);

		return value;
	}

	uint32_t get_control_word(
		uint32_t feedback, //3 bits
		uint32_t output_select, //3 bits
		bool load_acc,
		bool zcin_sel,
		bool a_sel,
		bool a_reg,
		bool a1_reg,
		bool a2_reg,
		bool b_sel,
		bool b_reg,
		bool b1_reg,
		bool b2_reg,
		bool c_reg,
		bool bc_reg,
		bool padd_sel,
		bool m_reg,
		bool sub
	) {
		uint32_t control_word = 0;

		control_word |= (feedback & 0b111) 		<< 18;  // top 3 bits
		control_word |= (output_select & 0b111) << 15;
		control_word |= (load_acc ? 1u : 0u)    << 14;
		control_word |= (zcin_sel ? 1u : 0u) 	<< 13;
		control_word |= (a_sel ? 1u : 0u) 		<< 12;
		control_word |= (a_reg ? 1u : 0u) 		<< 11;
		control_word |= (a1_reg ? 1u : 0u) 		<< 10;
		control_word |= (a2_reg ? 1u : 0u) 		<< 9;
		control_word |= (b_sel ? 1u : 0u) 		<< 8;
		control_word |= (b_reg ? 1u : 0u) 		<< 7;
		control_word |= (b1_reg ? 1u : 0u) 		<< 6;
		control_word |= (b2_reg ? 1u : 0u) 		<< 5;
		control_word |= (c_reg ? 1u : 0u) 		<< 4;
		control_word |= (bc_reg ? 1u : 0u) 		<< 3;
		control_word |= (padd_sel ? 1u : 0u) 	<< 2;
		control_word |= (m_reg ? 1u : 0u) 		<< 1;
		control_word |= (sub ? 1u : 0u);

		return control_word;
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
			log("Removing port %s from cell %s\n",
				log_id(p), log_id(cell));
			cell->unsetPort(p);
		}
	}

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing QL_DSPV2_TYPES pass.\n");

		size_t argidx = 1;
		extra_args(args, argidx, design);

		for (RTLIL::Module* module : design->selected_modules())
			for (RTLIL::Cell* cell: module->selected_cells())
			{
				if (cell->type != ID(QL_DSPV2) || !cell->hasParam(ID(MODE_BITS)))
					continue;
				
				RTLIL::Const mode_bits = cell->getParam(ID(MODE_BITS));
                

                int COEFF_0    = mode_bits.extract(0, 31).as_int();
                int ACC_FIR    = mode_bits.extract(32, 6).as_int();
                int ROUND      = mode_bits.extract(38, 3).as_int();
                int ZC_SHIFT   = mode_bits.extract(41, 5).as_int();
                int ZREG_SHIFT = mode_bits.extract(46, 5).as_int();
                int SHIFT_REG  = mode_bits.extract(51, 6).as_int();
                
                bool SATURATE  = mode_bits.extract(57).as_bool();
                bool SUBTRACT  = mode_bits.extract(58).as_bool();
                bool PRE_ADD   = mode_bits.extract(59).as_bool();
                
                bool A_SEL     = mode_bits.extract(60).as_bool();
                bool A_REG     = mode_bits.extract(61).as_bool();
                bool A1_REG    = mode_bits.extract(62).as_bool();
                bool A2_REG    = mode_bits.extract(63).as_bool();

                bool B_SEL     = mode_bits.extract(64).as_bool();
                bool B_REG     = mode_bits.extract(65).as_bool();
                bool B1_REG    = mode_bits.extract(66).as_bool();
                bool B2_REG    = mode_bits.extract(67).as_bool();	

                bool C_REG     = mode_bits.extract(68).as_bool();
                bool BC_REG    = mode_bits.extract(69).as_bool();
                bool M_REG     = mode_bits.extract(70).as_bool();
                bool ZCIN_SEL  = mode_bits.extract(71).as_bool();
                bool ACOUT_SEL = mode_bits.extract(72).as_bool();
                bool BCOUT_SEL = mode_bits.extract(73).as_bool();

                bool FRAC_MODE = mode_bits.extract(79).as_bool();

				int FEEDBACK = get_const_port_value(cell, ID(feedback));
				int OUTPUT_SELECT = get_const_port_value(cell, ID(output_select));
				int LOAD_ACC = get_const_port_value(cell, ID(load_acc));
				

				uint32_t control_word = get_control_word(FEEDBACK,
														 OUTPUT_SELECT,
														 LOAD_ACC,
														 ZCIN_SEL,
														 A_SEL,
														 A_REG,
														 A1_REG,
														 A2_REG,
														 B_SEL,
														 B_REG,
														 B1_REG,
														 B2_REG,
														 C_REG,
														 BC_REG,
														 PRE_ADD,
														 M_REG,
														 SUBTRACT);

				log("Control Word: %d\n", control_word);
				std::string type = "QL_DSPV2";
				switch (control_word){
					case 0b000000000000000000000: //MULT
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
					
					case 0b000000000100010000000: //MULT_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULT_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select)
													});
					
						break;
					
					case 0b000100000000000000000: //MULT_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULT_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b000100000100010000000: //MULT_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULT_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b000000000000100000000: //CASCADE_MULT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CASCADE_MULT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b_cin),
														ID(z),
														ID(feedback),
														ID(output_select),
														ID(b_cout)
													});
						break;
					
					case 0b000000000100110000000: //CASCADE_MULT_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CASCADE_MULT_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b_cin),
														ID(z),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(b_cout)
													});
					
						break;
					
					case 0b000100000000100000000: //CASCADE_MULT_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CASCADE_MULT_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b_cin),
														ID(z),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(b_cout)
													});
						break;
					
					case 0b000100000100110000000: //CASCADE_MULT_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CASCADE_MULT_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b_cin),
														ID(z),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(b_cout)
													});
						break;

					case 0b010010000000000000000: //CONCAT_CASCADE
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CONCAT_CASCADE"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(feedback),
														ID(output_select),
														ID(z_cout)
													});
						break;
					
					case 0b010010000100010000000: //CONCAT_CASCADE_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CONCAT_CASCADE_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z_cout)
													});
					
						break;
					
					case 0b010111000000000000000: //CONCAT_CASCADE_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CONCAT_CASCADE_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z_cout)
													});
						break;
					
					case 0b010111000100010000000: //CONCAT_CASCADE_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_CONCAT_CASCADE_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z_cout)
													});
						break;

					case 0b000001100000000000000: //MULTACC
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
					
					case 0b000001100100010000000: //MULTACC_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_REGIN"),
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
					
					case 0b000101100000000000000: //MULTACC_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_REGOUT"),
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
					
					case 0b000101100100010000000: //MULTACC_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_REGIN_REGOUT"),
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
					

					case 0b000001100000000000001: //MULTACC_NEG
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_NEG"),
												  pool<RTLIL::IdString>{ 
														ID(acc_reset),
													  	ID(load_acc),
														ID(feedback),
														ID(output_select),
														ID(a),
														ID(b),
														ID(z)
													});
						break;
					
					case 0b000001100100010000001: //MULTACC_NEG_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_NEG_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(acc_reset),
													  	ID(load_acc),
														ID(feedback),
														ID(output_select),
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset)
													});
					
						break;
					
					case 0b000101100000000000001: //MULTACC_NEG_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_NEG_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(acc_reset),
													  	ID(load_acc),
														ID(feedback),
														ID(output_select),
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset)
													});
						break;
					
					case 0b000101100100010000001: //MULTACC_NEG_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTACC_NEG_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(acc_reset),
													  	ID(load_acc),
														ID(feedback),
														ID(output_select),
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset)
													});
						break;
					
					case 0b010001100000000000000: //LOAD_ACC
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_LOAD_ACC"),
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

					case 0b000000000000000000100: //PREADDER_MULT
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

					case 0b000000000100000001100: //PREADDER_MULT_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_MULT_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					
					case 0b000100000100000001100: //PREADDER_MULT_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_MULT_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					
					case 0b000100000000000000100: //PREADDER_MULT_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_MULT_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					
					case 0b000100000100010010100: //PREADDER_REGIN_MULT_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_REGIN_MULT_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					
					case 0b000100000011010011100: //PREADDER_REGIN_REGOUT_MULT_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_PREADDER_REGIN_REGOUT_MULT_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(c),
														ID(clk),
														ID(reset),
														ID(feedback),
														ID(output_select),
														ID(z)
													});
						break;
					
					case 0b011010010000000000000: //MULTADD
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b011010010100010000000: //MULTADD_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
					
						break;
					
					case 0b011111010000000000000: //MULTADD_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b011111010100010000000: //MULTADD_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b011010010000000000001: //MULTADD_NEG
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_NEG"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b011010010100010000001: //MULTADD_NEG_REGIN
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_NEG_REGIN"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
					
						break;
					
					case 0b011111010000000000001: //MULTADD_NEG_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_NEG_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
						break;
					
					case 0b011111010100010000001: //MULTADD_NEG_REGIN_REGOUT
						transform_cell_with_ports(cell,
												  RTLIL::escape_id("QL_DSPV2_MULTADD_NEG_REGIN_REGOUT"),
												  pool<RTLIL::IdString>{ 
														ID(a),
														ID(b),
														ID(z),
														ID(clk),
														ID(reset),
														ID(z_cin),
														ID(z_cout),
														ID(feedback),
														ID(output_select)
													});
						break;

					default:
						break;

				}
			}
	}


} QlDSPV2TypesPass;

PRIVATE_NAMESPACE_END