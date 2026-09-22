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

// BLIF acceptance evidence -- test-plan section 7 (REQ-A3, REQ-C4).
//
// This is the direct evidence for "CAD can use the register in the BLIF file",
// and the cheapest place to catch a cell-name or port-set mismatch, which would
// otherwise surface as an obscure VPR failure deep in packing.

module blif_sdffr (
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

module blif_sdffnr (
    input  wire clk,
    input  wire rst_n,
    input  wire pad_in,
    input  wire other,
    output wire q_o
);
    reg q;
    assign q_o = q ^ other;

    always @(negedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= pad_in;
endmodule
