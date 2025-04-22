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
(* techmap_celltype = "$alu" *)
module _80_quicklogic_alu (A, B, CI, BI, X, Y, CO);
	parameter A_SIGNED = 0;
	parameter B_SIGNED = 0;
	parameter A_WIDTH = 2;
	parameter B_WIDTH = 2;
	parameter Y_WIDTH = 2;
	parameter _TECHMAP_CONSTVAL_CI_ = 0;
	parameter _TECHMAP_CONSTMSK_CI_ = 0;

	(* force_downto *)
	input [A_WIDTH-1:0] A;
	(* force_downto *)
	input [B_WIDTH-1:0] B;
	(* force_downto *)
	output [Y_WIDTH-1:0] X, Y;

	input CI, BI;
	(* force_downto *)
	output [Y_WIDTH-1:0] CO;


	wire _TECHMAP_FAIL_ = Y_WIDTH <= 2;

	(* force_downto *)
	wire [Y_WIDTH-1:0] A_buf, B_buf;
	\$pos #(.A_SIGNED(A_SIGNED), .A_WIDTH(A_WIDTH), .Y_WIDTH(Y_WIDTH)) A_conv (.A(A), .Y(A_buf));
	\$pos #(.A_SIGNED(B_SIGNED), .A_WIDTH(B_WIDTH), .Y_WIDTH(Y_WIDTH)) B_conv (.A(B), .Y(B_buf));

	(* force_downto *)
	wire [Y_WIDTH-1:0] AA = A_buf;
	(* force_downto *)
	wire [Y_WIDTH-1:0] BB = BI ? ~B_buf : B_buf;

	genvar i;
	wire co;

	(* force_downto *)
	//wire [Y_WIDTH-1:0] C = {CO, CI};
	wire [Y_WIDTH:0] C;
	(* force_downto *)
	wire [Y_WIDTH-1:0] S  = {AA ^ BB};
	assign CO[Y_WIDTH-1:0] = C[Y_WIDTH:1];
        //assign CO[Y_WIDTH-1] = co;

	generate
	     adder_carry intermediate_adder (
	       .cin     ( ),
	       .cout    (C[0]),
	       .p       (1'b0),
	       .g       (CI),
	       .sumout    ()
	     );
	endgenerate
	genvar i;
	generate if (Y_WIDTH > 2) begin
	  for (i = 0; i < Y_WIDTH-2; i = i + 1) begin:slice
		adder_carry  my_adder (
			.cin(C[i]),
			.g(AA[i]),
			.p(S[i]),
			.cout(C[i+1]),
		        .sumout(Y[i])
		);
	      end
	end endgenerate
	generate
	     adder_carry final_adder (
	       .cin     (C[Y_WIDTH-2]),
	       .cout    (),
	       .p       (1'b0),
	       .g       (1'b0),
	       .sumout    (co)
	     );
	endgenerate

	assign Y[Y_WIDTH-2] = S[Y_WIDTH-2] ^ co;
        assign C[Y_WIDTH-1] = S[Y_WIDTH-2] ? co : AA[Y_WIDTH-2];
	assign Y[Y_WIDTH-1] = S[Y_WIDTH-1] ^ C[Y_WIDTH-1];
        assign C[Y_WIDTH] = S[Y_WIDTH-1] ? C[Y_WIDTH-1] : AA[Y_WIDTH-1];

	assign X = S;
endmodule

module CARRY8(
  output [7:0] CO,
  output [7:0] O,
  input        CI,
  input  [7:0] DI, S
);
  parameter [15:0] LOCATION = 16'b0000000000000000;

  wire [8:0] C;
  wire c_int;
 
  
  adder_carry #(.LOCATION(LOCATION)) intermediate_adder (.cin( ), .cout(C[0]), .p(1'b0), .g(CI), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry0 ( .cin(C[0]), .g(DI[0]), .p(S[0]), .cout(C[1]), .sumout(O[0]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry1 ( .cin(C[1]), .g(DI[1]), .p(S[1]), .cout(C[2]), .sumout(O[1]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry2 ( .cin(C[2]), .g(DI[2]), .p(S[2]), .cout(C[3]), .sumout(O[2]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry3 ( .cin(C[3]), .g(DI[3]), .p(S[3]), .cout(C[4]), .sumout(O[3]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry4 ( .cin(C[4]), .g(DI[4]), .p(S[4]), .cout(C[5]), .sumout(O[4]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry5 ( .cin(C[5]), .g(DI[5]), .p(S[5]), .cout(C[6]), .sumout(O[5]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry6 ( .cin(C[6]), .g(DI[6]), .p(S[6]), .cout(C[7]), .sumout(O[6]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry7 ( .cin(C[7]), .g(DI[7]), .p(S[7]), .cout(C[8]), .sumout(O[7]) );
  adder_carry #(.LOCATION(LOCATION)) final_adder (.cin(C[8]), .cout(), .p(1'b0), .g(1'b0), .sumout(CO[7]) );
   
  assign CO[0] = S[0] ? CI : DI[0];
  assign CO[1] = S[1] ? CO[0] : DI[1];
  assign CO[2] = S[2] ? CO[1] : DI[2];
  assign CO[3] = S[3] ? CO[2] : DI[3];
  assign CO[4] = S[4] ? CO[3] : DI[4];
  assign CO[5] = S[5] ? CO[4] : DI[5];
  assign CO[6] = S[6] ? CO[5] : DI[6];
   
endmodule