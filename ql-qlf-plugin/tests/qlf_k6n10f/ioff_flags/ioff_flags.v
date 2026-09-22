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

// Flag behaviour matrix -- test-plan section 6 (REQ-C2, REQ-D1, REQ-D3).
//
// Both designs are active-low boundary registers, one with a reset and one
// without, so the flag combinations can be walked against a case that would
// otherwise promote.

// Reset-carrying input-side boundary register.
module flag_rst (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule

// Resetless input-side boundary register.
module flag_none (
    input  wire clk,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(posedge clk) q <= pad_in;
endmodule
