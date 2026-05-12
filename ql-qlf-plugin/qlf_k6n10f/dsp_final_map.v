// Copyright 2020-2022 F4PGA Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

module dsp_t1_20x18x64_cfg_ports (
    input  [19:0] a_i,
    input  [17:0] b_i,
    input  [ 5:0] acc_fir_i,
    output [37:0] z_o,
    output [17:0] dly_b_o,

    input         clock_i,
    input         reset_i,

    input  [2:0]  feedback_i,
    input         load_acc_i,
    input         unsigned_a_i,
    input         unsigned_b_i,

    input  [2:0]  output_select_i,
    input         saturate_enable_i,
    input  [5:0]  shift_right_i,
    input         round_i,
    input         subtract_i,
    input         register_inputs_i
);

    parameter [19:0] COEFF_0 = 20'd0;
    parameter [19:0] COEFF_1 = 20'd0;
    parameter [19:0] COEFF_2 = 20'd0;
    parameter [19:0] COEFF_3 = 20'd0;

    QL_DSP2 # (
        .MODE_BITS          ({COEFF_3, COEFF_2, COEFF_1, COEFF_0})
    ) _TECHMAP_REPLACE_ (
        .a                  (a_i),
        .b                  (b_i),
        .acc_fir            (acc_fir_i),
        .z                  (z_o),
        .dly_b              (dly_b_o),

        .clk                (clock_i),
        .reset              (reset_i),

        .feedback           (feedback_i),
        .load_acc           (load_acc_i),
        .unsigned_a         (unsigned_a_i),
        .unsigned_b         (unsigned_b_i),

        .f_mode             (1'b0), // No fracturation
        .output_select      (output_select_i),
        .saturate_enable    (saturate_enable_i),
        .shift_right        (shift_right_i),
        .round              (round_i),
        .subtract           (subtract_i),
        .register_inputs    (register_inputs_i)
    );

endmodule

module dsp_t1_10x9x32_cfg_ports (
    input  [ 9:0] a_i,
    input  [ 8:0] b_i,
    input  [ 5:0] acc_fir_i,
    output [18:0] z_o,
    output [ 8:0] dly_b_o,

    (* clkbuf_sink *)
    input         clock_i,
    input         reset_i,

    input  [2:0]  feedback_i,
    input         load_acc_i,
    input         unsigned_a_i,
    input         unsigned_b_i,

    input  [2:0]  output_select_i,
    input         saturate_enable_i,
    input  [5:0]  shift_right_i,
    input         round_i,
    input         subtract_i,
    input         register_inputs_i
);

    parameter [9:0] COEFF_0 = 10'd0;
    parameter [9:0] COEFF_1 = 10'd0;
    parameter [9:0] COEFF_2 = 10'd0;
    parameter [9:0] COEFF_3 = 10'd0;

    wire [37:0] z;
    wire [17:0] dly_b;

    QL_DSP2 # (
        .MODE_BITS          ({10'd0, COEFF_3,
                              10'd0, COEFF_2,
                              10'd0, COEFF_1,
                              10'd0, COEFF_0})
    ) _TECHMAP_REPLACE_ (
        .a                  ({10'd0, a_i}),
        .b                  ({ 9'd0, b_i}),
        .acc_fir            (acc_fir_i),
        .z                  (z),
        .dly_b              (dly_b),

        .clk                (clock_i),
        .reset              (reset_i),

        .feedback           (feedback_i),
        .load_acc           (load_acc_i),
        .unsigned_a         (unsigned_a_i),
        .unsigned_b         (unsigned_b_i),

        .f_mode             (1'b1), // Enable fractuation, Use the lower half
        .output_select      (output_select_i),
        .saturate_enable    (saturate_enable_i),
        .shift_right        (shift_right_i),
        .round              (round_i),
        .subtract           (subtract_i),
        .register_inputs    (register_inputs_i)
    );

    assign z_o = z[18:0];
    assign dly_b_o = dly_b_o[8:0];

endmodule

module dsp_t1_20x18x64_cfg_params (
    input  [19:0] a_i,
    input  [17:0] b_i,
    input  [ 5:0] acc_fir_i,
    output [37:0] z_o,
    output [17:0] dly_b_o,

    input         clock_i,
    input         reset_i,

    input  [2:0]  feedback_i,
    input         load_acc_i,
    input         unsigned_a_i,
    input         unsigned_b_i,
    input         subtract_i
);

    parameter [19:0] COEFF_0 = 20'd0;
    parameter [19:0] COEFF_1 = 20'd0;
    parameter [19:0] COEFF_2 = 20'd0;
    parameter [19:0] COEFF_3 = 20'd0;

    parameter [2:0] OUTPUT_SELECT   = 3'd0;
    parameter [0:0] SATURATE_ENABLE = 1'd0;
    parameter [5:0] SHIFT_RIGHT     = 6'd0;
    parameter [0:0] ROUND           = 1'd0;
    parameter [0:0] REGISTER_INPUTS = 1'd0;

    QL_DSP3 # (
        .MODE_BITS ({
            REGISTER_INPUTS,
            ROUND,
            SHIFT_RIGHT,
            SATURATE_ENABLE,
            OUTPUT_SELECT,
            1'b0, // Not fractured
            COEFF_3,
            COEFF_2,
            COEFF_1,
            COEFF_0
        })
    ) _TECHMAP_REPLACE_ (
        .a                  (a_i),
        .b                  (b_i),
        .acc_fir            (acc_fir_i),
        .z                  (z_o),
        .dly_b              (dly_b_o),

        .clk                (clock_i),
        .reset              (reset_i),

        .feedback           (feedback_i),
        .load_acc           (load_acc_i),
        .unsigned_a         (unsigned_a_i),
        .unsigned_b         (unsigned_b_i),
        .subtract           (subtract_i)
    );

endmodule

module dsp_t1_10x9x32_cfg_params (
    input  [ 9:0] a_i,
    input  [ 8:0] b_i,
    input  [ 5:0] acc_fir_i,
    output [18:0] z_o,
    output [ 8:0] dly_b_o,

    (* clkbuf_sink *)
    input         clock_i,
    input         reset_i,

    input  [2:0]  feedback_i,
    input         load_acc_i,
    input         unsigned_a_i,
    input         unsigned_b_i,
    input         subtract_i
);

    parameter [9:0] COEFF_0 = 10'd0;
    parameter [9:0] COEFF_1 = 10'd0;
    parameter [9:0] COEFF_2 = 10'd0;
    parameter [9:0] COEFF_3 = 10'd0;

    parameter [2:0] OUTPUT_SELECT   = 3'd0;
    parameter [0:0] SATURATE_ENABLE = 1'd0;
    parameter [5:0] SHIFT_RIGHT     = 6'd0;
    parameter [0:0] ROUND           = 1'd0;
    parameter [0:0] REGISTER_INPUTS = 1'd0;

    wire [37:0] z;
    wire [17:0] dly_b;

    QL_DSP3 # (
        .MODE_BITS  ({
            REGISTER_INPUTS,
            ROUND,
            SHIFT_RIGHT,
            SATURATE_ENABLE,
            OUTPUT_SELECT,
            1'b1, // Fractured
            10'd0, COEFF_3,
            10'd0, COEFF_2,
            10'd0, COEFF_1,
            10'd0, COEFF_0
        })
    ) _TECHMAP_REPLACE_ (
        .a                  ({10'd0, a_i}),
        .b                  ({ 9'd0, b_i}),
        .acc_fir            (acc_fir_i),
        .z                  (z),
        .dly_b              (dly_b),

        .clk                (clock_i),
        .reset              (reset_i),

        .feedback           (feedback_i),
        .load_acc           (load_acc_i),
        .unsigned_a         (unsigned_a_i),
        .unsigned_b         (unsigned_b_i),
        .subtract           (subtract_i)
    );

    assign z_o = z[18:0];
    assign dly_b_o = dly_b_o[8:0];

endmodule

//------------------------------------------------------------------------------
// Module
//------------------------------------------------------------------------------

module DSP38 #(
  parameter DSP_MODE = "MULTIPLY", // DSP arithmetic mode (MULTIPLY/MULTIPLY_ADD_SUB/MULTIPLY_ACCUMULATE)
  parameter [19:0] COEFF_0 = 20'h00000, // 20-bit A input coefficient 0
  parameter [19:0] COEFF_1 = 20'h00000, // 20-bit A input coefficient 1
  parameter [19:0] COEFF_2 = 20'h00000, // 20-bit A input coefficient 2
  parameter [19:0] COEFF_3 = 20'h00000, // 20-bit A input coefficient 3
  parameter OUTPUT_REG_EN = "TRUE", // Enable output register (TRUE/FALSE)
  parameter INPUT_REG_EN = "TRUE" // Enable input register (TRUE/FALSE)
)
(
  input wire [19:0] A, // 20-bit data input for multipluier or accumulator loading
  input wire [17:0] B, // 18-bit data input for multiplication
  input wire [5:0] ACC_FIR, // 6-bit left shift A input
  output wire [37:0] Z, // 38-bit data output
  output wire  [17:0] DLY_B, // 18-bit B registered output
  input wire CLK, // Clock
  input wire RESET, // Active high reset
  input wire [2:0] FEEDBACK, // 3-bit feedback input selects coefficient
  input wire LOAD_ACC, // Load accumulator input
  input wire SATURATE, // Saturate enable
  input wire [5:0] SHIFT_RIGHT, // 6-bit Shift right
  input wire ROUND, // Round
  input wire SUBTRACT, // Add or subtract
  input wire UNSIGNED_A, // Selects signed or unsigned data for A input
  input wire UNSIGNED_B // Selects signed or unsigned data for B input
);

generate
   if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "FALSE") begin

		QL_DSP2_MULT  mult (
			.a(A),
			.b(B),
			.z(Z),
	
			.reset(1'b0),
	
			.f_mode(1'b0),
	
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
	
			.output_select(3'b000),      // unregistered output: a * b (0)
			.register_inputs(1'b0)   // unregistered inputs
		);
   end else if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "TRUE") begin

		QL_DSP2_MULT_REGIN  mult_regin (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
	
			.output_select(3'b000),      // unregistered output: a * b (0)
			.register_inputs(1'b1)   // unregistered inputs
		);
   end else if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "FALSE") begin

		QL_DSP2_MULT_REGOUT  mult_regout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
	
			.output_select(3'b100),      // unregistered output: a * b (0)
			.register_inputs(1'b0)   // unregistered inputs
		);
   end else if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "TRUE") begin

		QL_DSP2_MULT_REGIN_REGOUT  mult_reginout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
	
			.output_select(3'b100),      // unregistered output: a * b (0)
			.register_inputs(1'b1)   // unregistered inputs
		);
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "FALSE") begin

		QL_DSP2_MULTACC  multacc (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
	        .load_acc(LOAD_ACC),
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
			
			.output_select(3'b010),      // unregistered output: a * b (0)
			.saturate_enable(SATURATE),
			.shift_right(SHIFT_RIGHT),
			.round(ROUND),
			.subtract(SUBTRACT),
			.register_inputs(1'b0)   // unregistered inputs
		);
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "TRUE") begin

		QL_DSP2_MULTACC_REGIN  multacc_regin (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
	        .load_acc(LOAD_ACC),
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
			
			.output_select(3'b010),      // unregistered output: a * b (0)
			.saturate_enable(SATURATE),
			.shift_right(SHIFT_RIGHT),
			.round(ROUND),
			.subtract(SUBTRACT),
			.register_inputs(1'b1)   // unregistered inputs
		);		
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "FALSE") begin

		QL_DSP2_MULTACC_REGOUT  multacc_regout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
	        .load_acc(LOAD_ACC),
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
			
			.output_select(3'b110),      // unregistered output: a * b (0)
			.saturate_enable(SATURATE),
			.shift_right(SHIFT_RIGHT),
			.round(ROUND),
			.subtract(SUBTRACT),
			.register_inputs(1'b0)   // unregistered inputs
		);
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "TRUE") begin

		QL_DSP2_MULTACC_REGIN_REGOUT  multacc_reginout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.f_mode(1'b0),
	
	        .load_acc(LOAD_ACC),
			.feedback(FEEDBACK),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
			
			.output_select(3'b110),      // unregistered output: a * b (0)
			.saturate_enable(SATURATE),
			.shift_right(SHIFT_RIGHT),
			.round(ROUND),
			.subtract(SUBTRACT),
			.register_inputs(1'b1)   // unregistered inputs
		);
   end else begin
   
		QL_DSP2_MULTADD  multadd (
			.a(A),
			.b(B),
			.z(Z),
	
	        .reset(1'b0),
	
			.f_mode(1'b0),
	
	        .load_acc(1'b0),
			.feedback(FEEDBACK),
			.acc_fir(6'h0),
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
			
			.output_select(3'b001),      // unregistered output: a * b (0)
			.saturate_enable(SATURATE),
			.shift_right(SHIFT_RIGHT),
			.round(ROUND),
			.subtract(SUBTRACT),
			.register_inputs(1'b0)   // unregistered inputs
		);
   end
endgenerate

endmodule

//------------------------------------------------------------------------------
// Module
//------------------------------------------------------------------------------

module DSPV2IPG #(
  parameter DSP_MODE = "MULTIPLY", // DSP arithmetic mode (MULTIPLY/MULTIPLY_ADD_SUB/MULTIPLY_ACCUMULATE)
  parameter [31:0] COEFF_0 = 32'h00000000, // 32-bit A input coefficient 0
  parameter OUTPUT_REG_EN = "TRUE", // Enable output register (TRUE/FALSE)
  parameter INPUT_REG_EN = "TRUE" // Enable input register (TRUE/FALSE)
)
(
  input wire [31:0] A, // 32-bit data input for multipluier or accumulator loading
  input wire [17:0] B, // 18-bit data input for multiplication
  input wire [17:0] C, // 18-bit data input for Pre-adder
  input wire [5:0] ACC_FIR, // 6-bit left shift A input
  output wire [49:0] Z, // 38-bit data output
  
  input wire [31:0] ACIN,
  input wire [17:0] BCIN,
  input wire [49:0] ZCIN,
  output wire  [31:0] ACOUT, 
  output wire  [17:0] BCOUT, 
  output wire  [49:0] ZCOUT, 
  
  input wire CLK, // Clock
  input wire RESET, // Active high reset 
  input wire ACC_RESET, // Active high accumulator reset
  input wire [2:0] FEEDBACK, // 3-bit feedback input selects coefficient
  input wire LOAD_ACC, // Load accumulator input
  input wire SATURATE, // Saturate enable
  input wire [5:0] SHIFT_RIGHT, // 6-bit Shift right
  input wire [2:0] ROUND, // Round
  input wire SUBTRACT, // Add or subtract
  input wire UNSIGNED_A, // Selects signed or unsigned data for A input
  input wire UNSIGNED_B // Selects signed or unsigned data for B input
);

generate
   if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "FALSE") begin

		QL_DSPV2_MULT  #(
		    .MODE_BITS({48'h000000000000,COEFF_0})
			)
			mult (
			.a(A),
			.b(B),
			.z(Z),
	
			.feedback(FEEDBACK),
			.output_select(3'b000)
		);
	
   end else if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "TRUE") begin

		QL_DSPV2_MULT_REGIN #(
		    .MODE_BITS({48'h000220000000,COEFF_0})
			) 
			mult_regin (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
		
			.feedback(FEEDBACK),
			.output_select(3'b000)
		);
		
   end else if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "FALSE") begin

		QL_DSPV2_MULT_REGOUT #(
		    .MODE_BITS({48'h000000000000,COEFF_0})
			)  
			mult_regout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	
			.feedback(FEEDBACK),
			.output_select(3'b100)
		);
		
   end else if (DSP_MODE == "MULTIPLY" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "TRUE") begin

		QL_DSPV2_MULT_REGIN_REGOUT #(
		    .MODE_BITS({48'h000220000000,COEFF_0})
			)   
			mult_reginout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),

			.feedback(FEEDBACK),
			.output_select(3'b100)
		);
		
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "FALSE") begin

		QL_DSPV2_MULTACC #(
		    .MODE_BITS({48'h000000000000,COEFF_0})
			)   
			multacc (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
			.acc_reset(ACC_RESET),
	        .load_acc(LOAD_ACC),
			
			.feedback(FEEDBACK),
			.output_select(3'b010)
		);
		
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "FALSE" & INPUT_REG_EN == "TRUE") begin

		QL_DSPV2_MULTACC_REGIN #(
		    .MODE_BITS({48'h000220000000,COEFF_0})
			)   
			multacc_regin (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
			.acc_reset(ACC_RESET),
	        .load_acc(LOAD_ACC),
			
			.feedback(FEEDBACK),
			.output_select(3'b010)
		);
		
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "FALSE") begin

		QL_DSPV2_MULTACC_REGOUT #(
		    .MODE_BITS({48'h000000000000,COEFF_0})
			)     
			multacc_regout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
	        .acc_reset(ACC_RESET),
	        .load_acc(LOAD_ACC),
			
			.feedback(FEEDBACK),
			.output_select(3'b110)
		);
		
   end else if (DSP_MODE == "MULTIPLY_ACCUMULATE" & OUTPUT_REG_EN == "TRUE" & INPUT_REG_EN == "TRUE") begin

		QL_DSPV2_MULTACC_REGIN_REGOUT #(
		    .MODE_BITS({48'h000220000000,COEFF_0})
			)    
			multacc_reginout (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(CLK),
			.reset(RESET),
			.acc_reset(ACC_RESET),
	        .load_acc(LOAD_ACC),
			
			.feedback(FEEDBACK),
			.output_select(3'b110)
		);
		
   end else begin
   
		QL_DSPV2_MULTADD #(
		    .MODE_BITS({48'h000000000000,COEFF_0})
			)    
			multadd (
			.a(A),
			.b(B),
			.z(Z),
	
	        .clk(),
			.reset(),
			.acc_reset(),
	        .load_acc(),
			
			.z_cin(ZCIN),
			.z_cout(ZCOUT),
			
			.feedback(FEEDBACK),
			.output_select(3'b001)
		);
   end
endgenerate

endmodule

`ifdef DSPV2IPG
module dspv2_32x18x64_cfg_ports (
    input  wire [31:0] a_i,
    input  wire [17:0] b_i,
    input  wire [17:0] c_i,
    output wire [49:0] z_o,

    (* clkbuf_sink *)
    input  wire        clock_i,
    input  wire        reset_i,
    input  wire        acc_reset_i,

    input  wire [ 2:0] feedback_i,
    input  wire        load_acc_i,
    input  wire [ 2:0] output_select_i,

    input  wire [31:0] a_cin_i,
    input  wire [17:0] b_cin_i,
    input  wire [49:0] z_cin_i,

    output wire [31:0] a_cout_o,
    output wire [17:0] b_cout_o,
    output wire [49:0] z_cout_o
);
    parameter [31:0] COEFF_0    = 32'h0;
    parameter [5:0]  ACC_FIR    = 6'h0;
    parameter [2:0]  ROUND      = 3'h0;
    parameter [4:0]  ZC_SHIFT   = 5'h0;
    parameter [4:0]  ZREG_SHIFT = 5'h0;
    parameter [5:0]  SHIFT_REG  = 6'h0;
    parameter        SATURATE   = 1'b0;
    parameter        SUBTRACT   = 1'b0;
    parameter        PRE_ADD    = 1'b0;
    parameter        A_SEL      = 1'b0;
    parameter        A_REG      = 1'b0;
    parameter        A1_REG     = 1'b0;
    parameter        A2_REG     = 1'b0;
    parameter        B_SEL      = 1'b0;
    parameter        B_REG      = 1'b0;
    parameter        B1_REG     = 1'b0;
    parameter        B2_REG     = 1'b0;
    parameter        C_REG      = 1'b0;
    parameter        BC_REG     = 1'b0;
    parameter        M_REG      = 1'b0;
    parameter        ZCIN_REG   = 1'b0;
    parameter        ACOUT_SEL  = 1'b0;
    parameter        BCOUT_SEL  = 1'b0;
    parameter        FRAC_MODE  = 1'b0;  // 32x18x64 DSP

    (* is_inferred = 1 *)
    QL_DSPV2 #(
        .MODE_BITS({FRAC_MODE, 5'h0, BCOUT_SEL, ACOUT_SEL,
                    ZCIN_REG, M_REG, BC_REG, C_REG,
                    B2_REG, B1_REG, B_REG, B_SEL,
                    A2_REG, A1_REG, A_REG, A_SEL,
                    PRE_ADD, SUBTRACT, SATURATE,
                    SHIFT_REG, ZREG_SHIFT, ZC_SHIFT,
                    ROUND, ACC_FIR, COEFF_0})
    ) _TECHMAP_REPLACE_ (
        .a              (a_i),
        .b              (b_i),
        .c              (c_i),
        .load_acc       (load_acc_i),
        .feedback       (feedback_i),
        .output_select  (output_select_i),
        .z              (z_o),

        .clk            (clock_i),
        .reset          (reset_i),
        .acc_reset      (acc_reset_i),

        .a_cin          (a_cin_i),
        .b_cin          (b_cin_i),
        .z_cin          (z_cin_i),

        .z_cout         (z_cout_o),
        .a_cout         (a_cout_o),
        .b_cout         (b_cout_o)
    );
endmodule

module dspv2_16x9x32_cfg_ports (
    input  wire [15:0] a_i,
    input  wire [ 8:0] b_i,
    input  wire [ 8:0] c_i,
    output wire [24:0] z_o,

    (* clkbuf_sink *)
    input  wire        clock_i,
    input  wire        reset_i,
    input  wire        acc_reset_i,

    input  wire [ 2:0] feedback_i,
    input  wire        load_acc_i,
    input  wire [ 2:0] output_select_i,

    input  wire [15:0] a_cin_i,
    input  wire [ 8:0] b_cin_i,
    input  wire [24:0] z_cin_i,

    output wire [15:0] a_cout_o,
    output wire [ 8:0] b_cout_o,
    output wire [24:0] z_cout_o
);
    parameter [15:0] COEFF_0    = 16'h0;
    parameter [5:0]  ACC_FIR    = 6'h0;
    parameter [2:0]  ROUND      = 3'h0;
    parameter [4:0]  ZC_SHIFT   = 5'h0;
    parameter [4:0]  ZREG_SHIFT = 5'h0;
    parameter [5:0]  SHIFT_REG  = 6'h0;
    parameter        SATURATE   = 1'b0;
    parameter        SUBTRACT   = 1'b0;
    parameter        PRE_ADD    = 1'b0;
    parameter        A_SEL      = 1'b0;
    parameter        A_REG      = 1'b0;
    parameter        A1_REG     = 1'b0;
    parameter        A2_REG     = 1'b0;
    parameter        B_SEL      = 1'b0;
    parameter        B_REG      = 1'b0;
    parameter        B1_REG     = 1'b0;
    parameter        B2_REG     = 1'b0;
    parameter        C_REG      = 1'b0;
    parameter        BC_REG     = 1'b0;
    parameter        M_REG      = 1'b0;
    parameter        ZCIN_REG   = 1'b0;
    parameter        ACOUT_SEL  = 1'b0;
    parameter        BCOUT_SEL  = 1'b0;
    parameter        FRAC_MODE  = 1'b1;  // 16x9x32 DSP (fractured)

    (* is_inferred = 1 *)
    QL_DSPV2 #(
        .MODE_BITS({FRAC_MODE, 5'h0, BCOUT_SEL, ACOUT_SEL,
                    ZCIN_REG, M_REG, BC_REG, C_REG,
                    B2_REG, B1_REG, B_REG, B_SEL,
                    A2_REG, A1_REG, A_REG, A_SEL,
                    PRE_ADD, SUBTRACT, SATURATE,
                    SHIFT_REG, ZREG_SHIFT, ZC_SHIFT,
                    ROUND, ACC_FIR, 16'h0, COEFF_0})
    ) _TECHMAP_REPLACE_ (
        .a              (a_i),
        .b              (b_i),
        .c              (c_i),
        .load_acc       (load_acc_i),
        .feedback       (feedback_i),
        .output_select  (output_select_i),
        .z              (z_o),

        .clk            (clock_i),
        .reset          (reset_i),
        .acc_reset      (acc_reset_i),

        .a_cin          (a_cin_i),
        .b_cin          (b_cin_i),
        .z_cin          (z_cin_i),

        .z_cout         (z_cout_o),
        .a_cout         (a_cout_o),
        .b_cout         (b_cout_o)
    );
endmodule
`endif