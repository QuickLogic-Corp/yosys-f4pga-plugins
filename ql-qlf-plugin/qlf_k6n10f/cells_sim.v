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

`timescale 1ps/1ps

`default_nettype none
(* abc9_lut=1 *)
module LUT1(output wire O, input wire I0);
  parameter [1:0] INIT = 0;
  assign O = I0 ? INIT[1] : INIT[0];
  specify
    (I0 => O) = 74;
  endspecify
endmodule

(* abc9_lut=2 *)
module LUT2(output wire O, input wire I0, I1);
  parameter [3:0] INIT = 0;
  wire [ 1: 0] s1 = I1 ? INIT[ 3: 2] : INIT[ 1: 0];
  assign O = I0 ? s1[1] : s1[0];
  specify
    (I0 => O) = 116;
    (I1 => O) = 74;
  endspecify
endmodule

(* abc9_lut=3 *)
module LUT3(output wire O, input wire I0, I1, I2);
  parameter [7:0] INIT = 0;
  wire [ 3: 0] s2 = I2 ? INIT[ 7: 4] : INIT[ 3: 0];
  wire [ 1: 0] s1 = I1 ?   s2[ 3: 2] :   s2[ 1: 0];
  assign O = I0 ? s1[1] : s1[0];
  specify
    (I0 => O) = 162;
    (I1 => O) = 116;
    (I2 => O) = 174;
  endspecify
endmodule

(* abc9_lut=3 *)
module LUT4(output wire O, input wire I0, I1, I2, I3);
  parameter [15:0] INIT = 0;
  wire [ 7: 0] s3 = I3 ? INIT[15: 8] : INIT[ 7: 0];
  wire [ 3: 0] s2 = I2 ?   s3[ 7: 4] :   s3[ 3: 0];
  wire [ 1: 0] s1 = I1 ?   s2[ 3: 2] :   s2[ 1: 0];
  assign O = I0 ? s1[1] : s1[0];
  specify
    (I0 => O) = 201;
    (I1 => O) = 162;
    (I2 => O) = 116;
    (I3 => O) = 74;
  endspecify
endmodule

(* abc9_lut=3 *)
module LUT5(output wire O, input wire I0, I1, I2, I3, I4);
  parameter [31:0] INIT = 0;
  wire [15: 0] s4 = I4 ? INIT[31:16] : INIT[15: 0];
  wire [ 7: 0] s3 = I3 ?   s4[15: 8] :   s4[ 7: 0];
  wire [ 3: 0] s2 = I2 ?   s3[ 7: 4] :   s3[ 3: 0];
  wire [ 1: 0] s1 = I1 ?   s2[ 3: 2] :   s2[ 1: 0];
  assign O = I0 ? s1[1] : s1[0];
  specify
    (I0 => O) = 228;
    (I1 => O) = 189;
    (I2 => O) = 143;
    (I3 => O) = 100;
    (I4 => O) = 55;
  endspecify
endmodule

(* abc9_lut=5 *)
module LUT6(output wire O, input wire I0, I1, I2, I3, I4, I5);
  parameter [63:0] INIT = 0;
  wire [31: 0] s5 = I5 ? INIT[63:32] : INIT[31: 0];
  wire [15: 0] s4 = I4 ?   s5[31:16] :   s5[15: 0];
  wire [ 7: 0] s3 = I3 ?   s4[15: 8] :   s4[ 7: 0];
  wire [ 3: 0] s2 = I2 ?   s3[ 7: 4] :   s3[ 3: 0];
  wire [ 1: 0] s1 = I1 ?   s2[ 3: 2] :   s2[ 1: 0];
  assign O = I0 ? s1[1] : s1[0];
  specify
    (I0 => O) = 251;
    (I1 => O) = 212;
    (I2 => O) = 166;
    (I3 => O) = 123;
    (I4 => O) = 77;
    (I5 => O) = 43;
  endspecify
endmodule

(* abc9_box, lib_whitebox *)
(* blackbox *)
(* keep *)
module adder_carry(
    output wire sumout,
    (* abc9_carry *)
    output wire cout,
    input wire p,
    input wire g,
    (* abc9_carry *)
    input wire cin
);
	parameter [15:0] LOCATION = 16'b0000000000000000;
	
    assign sumout = p ^ cin;
    assign cout = p ? cin : g;
	
    specify
        (p => sumout) = 35;
        (g => sumout) = 35;
        (cin => sumout) = 40;
        (p => cout) = 67;
        (g => cout) = 65;
        (cin => cout) = 69;
    endspecify

endmodule

(* abc9_box, lib_whitebox *)
(* blackbox *)
(* keep *)
module lut6(
    input wire [0:5] in,
    output wire out
);
    parameter [0:63] LUT = 0;
    // Effective LUT input
    wire [0:5] li = in;

    // Output function
    wire [0:31] s1 = li[0] ?
    {LUT[0] , LUT[2] , LUT[4] , LUT[6] , LUT[8] , LUT[10], LUT[12], LUT[14], 
     LUT[16], LUT[18], LUT[20], LUT[22], LUT[24], LUT[26], LUT[28], LUT[30],
     LUT[32], LUT[34], LUT[36], LUT[38], LUT[40], LUT[42], LUT[44], LUT[46],
     LUT[48], LUT[50], LUT[52], LUT[54], LUT[56], LUT[58], LUT[60], LUT[62]}:
    {LUT[1] , LUT[3] , LUT[5] , LUT[7] , LUT[9] , LUT[11], LUT[13], LUT[15], 
     LUT[17], LUT[19], LUT[21], LUT[23], LUT[25], LUT[27], LUT[29], LUT[31],
     LUT[33], LUT[35], LUT[37], LUT[39], LUT[41], LUT[43], LUT[45], LUT[47],
     LUT[49], LUT[51], LUT[53], LUT[55], LUT[57], LUT[59], LUT[61], LUT[63]};

    wire [0:15] s2 = li[1] ?
    {s1[0] , s1[2] , s1[4] , s1[6] , s1[8] , s1[10], s1[12], s1[14],
     s1[16], s1[18], s1[20], s1[22], s1[24], s1[26], s1[28], s1[30]}:
    {s1[1] , s1[3] , s1[5] , s1[7] , s1[9] , s1[11], s1[13], s1[15],
     s1[17], s1[19], s1[21], s1[23], s1[25], s1[27], s1[29], s1[31]};

    wire [0:7] s3 = li[2] ?
    {s2[0], s2[2], s2[4], s2[6], s2[8], s2[10], s2[12], s2[14]}:
    {s2[1], s2[3], s2[5], s2[7], s2[9], s2[11], s2[13], s2[15]};

    wire [0:3] s4 = li[3] ? {s3[0], s3[2], s3[4], s3[6]}:
                            {s3[1], s3[3], s3[5], s3[7]};

    wire [0:1] s5 = li[4] ? {s4[0], s4[2]} : {s4[1], s4[3]};

    assign out = li[5] ? s5[0] : s5[1];

  specify
    (in[0] => out) = 251;
    (in[1] => out) = 212;
    (in[2] => out) = 166;
    (in[3] => out) = 123;
    (in[4] => out) = 77;
    (in[5] => out) = 43;
  endspecify

endmodule

(* abc9_flop, lib_whitebox *)
module dff(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
	input wire R
);
    initial Q <= 1'b0;

    always @(posedge C or negedge R)
      if (!R)
        Q <= 1'b0;
      else
        Q <= D;

    specify
	    (posedge C=>(Q+:D)) = 285;
		(R => Q) = 0;
	    $setuphold(posedge C, D, 56, 0);
        $setuphold(posedge C, R, 0, 0);
        $recrem(posedge R, posedge C, 0, 0);
    endspecify

endmodule

(* abc9_flop, lib_whitebox *)
module dffn(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
	input wire R
);
    initial Q <= 1'b0;

    always @(negedge C or negedge R)
      if (!R)
        Q <= 1'b0;
      else
        Q <= D;
	  
    specify
	    (negedge C=>(Q+:D)) = 285;
	    $setuphold(negedge C, D, 56, 0);
        $setuphold(negedge C, R, 0, 0);
        $recrem(posedge R, negedge C, 0, 0);
    endspecify

endmodule

(* abc9_flop, lib_whitebox *)
module dffre(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
    input wire E,
    input wire R
);
    initial Q <= 1'b0;

    always @(posedge C or negedge R)
      if (!R)
        Q <= 1'b0;
      else if (E)
        Q <= D;

    specify
      (posedge C => (Q +: D)) = 280;
      (R => Q) = 0;
      $setuphold(posedge C, D, 56, 0);
      $setuphold(posedge C, E, 32, 0);
      $setuphold(posedge C, R, 0, 0);
      $recrem(posedge R, posedge C, 0, 0);
    endspecify

endmodule


(* abc9_flop, lib_whitebox *)
module dffnre(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
    input wire E,
    input wire R
);
    initial Q <= 1'b0;

    always @(negedge C or negedge R)
      if (!R)
        Q <= 1'b0;
      else if (E)
        Q <= D;
		
    specify
      (negedge C => (Q +: D)) = 280;
      (R => Q) = 0;
      $setuphold(negedge C, D, 56, 0);
      $setuphold(negedge C, E, 32, 0);
      $setuphold(negedge C, R, 0, 0);
      $recrem(posedge R, negedge C, 0, 0);
    endspecify

endmodule

(* abc9_flop, lib_whitebox *)
module sdffre(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
    input wire E,
    input wire R
);
    initial Q <= 1'b0;

    always @(posedge C)
      if (!R)
        Q <= 1'b0;
      else if (E)
        Q <= D;
		
    specify
        (posedge C => (Q +: D)) = 280;
        $setuphold(posedge C, D, 56, 0);
        $setuphold(posedge C, R, 32, 0);
        $setuphold(posedge C, E, 0, 0);
    endspecify

endmodule

(* abc9_flop, lib_whitebox *)
module sdffnre(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
    input wire E,
    input wire R
);
    initial Q <= 1'b0;

    always @(negedge C)
      if (!R)
        Q <= 1'b0;
      else if (E)
        Q <= D;
		
    specify
        (negedge C => (Q +: D)) = 280;
        $setuphold(negedge C, D, 56, 0);
        $setuphold(negedge C, R, 32, 0);
        $setuphold(negedge C, E, 0, 0);
    endspecify

endmodule

(* abc9_flop, lib_whitebox *)
module sh_dffre(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
    input wire E,
    input wire R
);
    initial Q <= 1'b0;

    always @(posedge C or negedge R)
      if (!R)
        Q <= 1'b0;
      else if (E)
        Q <= D;

    specify
      (posedge C => (Q +: D)) = 280;
      (R => Q) = 0;
      $setuphold(posedge C, D, 56, 0);
      $setuphold(posedge C, E, 32, 0);
      $setuphold(posedge C, R, 0, 0);
      $recrem(posedge R, posedge C, 0, 0);
    endspecify

endmodule


(* abc9_flop, lib_whitebox *)
module sh_dffnre(
    output reg Q,
    input wire D,
    (* clkbuf_sink *)
    input wire C,
    input wire E,
    input wire R
);
    initial Q <= 1'b0;

    always @(negedge C or negedge R)
      if (!R)
        Q <= 1'b0;
      else if (E)
        Q <= D;
		
    specify
      (negedge C => (Q +: D)) = 280;
      (R => Q) = 0;
      $setuphold(negedge C, D, 56, 0);
      $setuphold(negedge C, E, 32, 0);
      $setuphold(negedge C, R, 0, 0);
      $recrem(posedge R, negedge C, 0, 0);
    endspecify

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
