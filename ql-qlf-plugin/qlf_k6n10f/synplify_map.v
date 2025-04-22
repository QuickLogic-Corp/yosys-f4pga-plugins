module LUT1(output O, input I0);
  parameter [1:0] INIT = 0;
  \$lut #(
    .WIDTH(1),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A(I0),
    .Y(O)
  );
endmodule
module LUT2(output O, input I0, I1);
  parameter [3:0] INIT = 0;
  \$lut #(
    .WIDTH(2),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I1, I0}),
    .Y(O)
  );
endmodule
module LUT3(output O, input I0, I1, I2);
  parameter [7:0] INIT = 0;
  \$lut #(
    .WIDTH(3),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I2, I1, I0}),
    .Y(O)
  );
endmodule
module LUT4(output O, input I0, I1, I2, I3);
  parameter [15:0] INIT = 0;
  \$lut #(
    .WIDTH(4),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I3, I2, I1, I0}),
    .Y(O)
  );
endmodule
module LUT5(output O, input I0, I1, I2, I3, I4);
  parameter [31:0] INIT = 0;
  \$lut #(
    .WIDTH(5),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I4, I3, I2, I1, I0}),
    .Y(O)
  );
endmodule
module LUT6(output O, input I0, I1, I2, I3, I4, I5);
  parameter [63:0] INIT = 0;
  \$lut #(
    .WIDTH(6),
    .LUT(INIT)
  ) _TECHMAP_REPLACE_ (
    .A({I5, I4, I3, I2, I1, I0}),
    .Y(O)
  );
endmodule

module VCC(output P);
  assign P = 1;
endmodule

module GND(output G);
  assign G = 0;
endmodule

module IBUF (I, O);
  input I;
  output O;
  assign O = I;
endmodule

module OBUF (I, O);
  input I;
  output O;
  assign O = I;
endmodule

/*
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
*/

module CARRY8(
  output [7:0] CO,
  output [7:0] O,
  input        CI,
  input  [7:0] DI, S
);
  parameter [15:0] LOCATION = 16'b0000000000000000;

  wire [7:0] CO;
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
  
  LUT3 co0_out (
	.I0(DI[0]),
	.I1(CI),
	.I2(S[0]),
	.O(CO[0])
	);
  defparam co0_out.INIT=8'hCA;
  
  LUT3 co1_out (
	.I0(DI[1]),
	.I1(CO[0]),
	.I2(S[1]),
	.O(CO[1])
	);
  defparam co1_out.INIT=8'hCA;
  
  LUT3 co2_out (
	.I0(DI[2]),
	.I1(CO[1]),
	.I2(S[2]),
	.O(CO[2])
	);
  defparam co2_out.INIT=8'hCA;
  
  LUT3 co3_out (
	.I0(DI[3]),
	.I1(CO[2]),
	.I2(S[3]),
	.O(CO[3])
	);
  defparam co3_out.INIT=8'hCA;
  
  LUT3 co4_out (
	.I0(DI[4]),
	.I1(CO[3]),
	.I2(S[4]),
	.O(CO[4])
	);
  defparam co4_out.INIT=8'hCA;
  
  LUT3 co5_out (
	.I0(DI[5]),
	.I1(CO[4]),
	.I2(S[5]),
	.O(CO[5])
	);
  defparam co5_out.INIT=8'hCA;
  
  LUT3 co6_out (
	.I0(DI[6]),
	.I1(CO[5]),
	.I2(S[6]),
	.O(CO[6])
	);
  defparam co6_out.INIT=8'hCA;
   
endmodule

/*
module CARRY8(
  output [7:0] CO,
  output [7:0] O,
  input        CI,
  input  [7:0] DI, S
);
  parameter [15:0] LOCATION = 16'b0000000000000000;

  wire [7:0] CO;
  wire [8:0] c_int;
 
  
  adder_carry #(.LOCATION(LOCATION)) intermediate_adder (.cin( ), .cout(c_int[0]), .p(1'b0), .g(CI), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry0 ( .cin(c_int[0]), .g(DI[0]), .p(S[0]), .cout(c_int[1]), .sumout(O[0]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out0 ( .cin(c_int[1]), .g(1'b0), .p(1'b1), .cout(CO[0]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry1 ( .cin(CO[0]), .g(DI[1]), .p(S[1]), .cout(c_int[2]), .sumout(O[1]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out1 ( .cin(c_int[2]), .g(1'b0), .p(1'b1), .cout(CO[1]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry2 ( .cin(CO[1]), .g(DI[2]), .p(S[2]), .cout(c_int[3]), .sumout(O[2]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out2 ( .cin(c_int[3]), .g(1'b0), .p(1'b1), .cout(CO[2]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry3 ( .cin(CO[2]), .g(DI[3]), .p(S[3]), .cout(c_int[4]), .sumout(O[3]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out3 ( .cin(c_int[4]), .g(1'b0), .p(1'b1), .cout(CO[3]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry4 ( .cin(CO[3]), .g(DI[4]), .p(S[4]), .cout(c_int[5]), .sumout(O[4]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out4 ( .cin(c_int[5]), .g(1'b0), .p(1'b1), .cout(CO[4]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry5 ( .cin(CO[4]), .g(DI[5]), .p(S[5]), .cout(c_int[6]), .sumout(O[5]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out5 ( .cin(c_int[6]), .g(1'b0), .p(1'b1), .cout(CO[5]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry6 ( .cin(CO[5]), .g(DI[6]), .p(S[6]), .cout(c_int[7]), .sumout(O[6]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out6 ( .cin(c_int[7]), .g(1'b0), .p(1'b1), .cout(CO[6]), .sumout() );
  adder_carry #(.LOCATION(LOCATION)) add_carry7 ( .cin(CO[6]), .g(DI[7]), .p(S[7]), .cout(c_int[8]), .sumout(O[7]) );
  adder_carry #(.LOCATION(LOCATION)) add_carry_out7 (.cin(c_int[8]), .cout(), .p(1'b0), .g(1'b0), .sumout(CO[7]) );
     
endmodule
*/