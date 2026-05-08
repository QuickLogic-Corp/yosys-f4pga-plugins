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

// Techmap source for the DSPv2 inference flow.
//
// Lowers `mul2dsp`-emitted `$__MUL32X18` / `$__MUL16X9` cells into the
// `dspv2_*_cfg_ports` wrappers defined in `dspv2_sim.v`. The wrappers carry
// every DSPv2 control as an individual parameter so subsequent passes
// (`ql_dsp`, `ql_dsp_simd -dspv2`) can fold register pipelines and pack
// fractured pairs before `dspv2_final_map.v` collapses everything into the
// 80-bit `MODE_BITS` of the hard `QL_DSPV2` primitive.

module \$__MUL32X18 (input [31:0] A, input [17:0] B, output [49:0] Y);
    parameter A_SIGNED = 0;
    parameter B_SIGNED = 0;
    parameter A_WIDTH  = 32;
    parameter B_WIDTH  = 18;
    parameter Y_WIDTH  = 50;

    (* is_inferred = 1 *)
    dspv2_32x18x64_cfg_ports _TECHMAP_REPLACE_ (
        .a_i                (A),
        .b_i                (B),
        .c_i                (18'd0),
        .z_o                (Y),

        .clock_i            (1'bx),
        .reset_i            (1'bx),
        .acc_reset_i        (1'b0),

        .feedback_i         (3'd0),
        .load_acc_i         (1'b0),
        .output_select_i    (3'd0),

        .a_cin_i            (32'd0),
        .b_cin_i            (18'd0),
        .z_cin_i            (50'd0)
    );
endmodule

module \$__MUL16X9 (input [15:0] A, input [8:0] B, output [24:0] Y);
    parameter A_SIGNED = 0;
    parameter B_SIGNED = 0;
    parameter A_WIDTH  = 16;
    parameter B_WIDTH  = 9;
    parameter Y_WIDTH  = 25;

    (* is_inferred = 1 *)
    dspv2_16x9x32_cfg_ports _TECHMAP_REPLACE_ (
        .a_i                (A),
        .b_i                (B),
        .c_i                (9'd0),
        .z_o                (Y),

        .clock_i            (1'bx),
        .reset_i            (1'bx),
        .acc_reset_i        (1'b0),

        .feedback_i         (3'd0),
        .load_acc_i         (1'b0),
        .output_select_i    (3'd0),

        .a_cin_i            (16'd0),
        .b_cin_i            (9'd0),
        .z_cin_i            (25'd0)
    );
endmodule
