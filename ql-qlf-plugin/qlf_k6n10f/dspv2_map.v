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

module \$__QL_MUL20X18 (input [31:0] A, input [17:0] B, output [49:0] Y);
    parameter A_WIDTH = 0;
    parameter B_WIDTH = 0;
    parameter Y_WIDTH = 0;

    wire [31:0] a;
    wire [17:0] b;
    wire [49:0] z;

    assign a = (A_WIDTH == 32) ? A : {{(32 - A_WIDTH){A[A_WIDTH-1]}}, A};
 
    assign b = (B_WIDTH == 18) ? B : {{(18 - B_WIDTH){B[B_WIDTH-1]}}, B};

    (* is_inferred=1 *)
    dspv2_32x18x64_cfg_ports  _TECHMAP_REPLACE_ (
        .a_i                (a),
        .b_i                (b),
        .c_i             (6'd0),
        .z_o                (z),

        .acc_reset_i	    (1'b0),
        .feedback_i         (3'd0),
        .load_acc_i         (1'b0),
        .output_select_i    (3'd0),
		
        .a_cin_i            (32'h0),
        .b_cin_i            (18'h0),
        .z_cin_i            (50'h0),
		
		.a_cout_o           (),
        .b_cout_o           (),
        .z_cout_o           ()
    );
	

    assign Y = z;

endmodule

module \$__QL_MUL10X9 (input [9:0] A, input [8:0] B, output [18:0] Y);
    parameter A_WIDTH = 0;
    parameter B_WIDTH = 0;
    parameter Y_WIDTH = 0;

    wire [15:0] a;
    wire [ 8:0] b;
    wire [24:0] z;

    assign a = (A_WIDTH == 16) ? A : {{(16 - A_WIDTH){A[A_WIDTH-1]}}, A};

    assign b = (B_WIDTH ==  9) ? B : {{( 9 - B_WIDTH){B[B_WIDTH-1]}}, B};

    (* is_inferred=1 *)
    (* keep *)
    dspv2_16x9x32_cfg_ports _TECHMAP_REPLACE_ (
        .a_i                (a),
        .b_i                (b),
        .c_i             (9'h0),
        .z_o                (z),

        .acc_reset_i	    (1'b0),
        .feedback_i         (3'd0),
        .load_acc_i         (1'b0),
        .output_select_i    (3'd0),
		
        .a_cin_i            (16'h0),
        .b_cin_i            (9'h0),
        .z_cin_i            (25'h0),
		
		.a_cout_o           (),
        .b_cout_o           (),
        .z_cout_o           ()
    );

    assign Y = z;

endmodule
