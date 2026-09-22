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

// One small design with something for every synthesis option to act on: a
// multiplier (DSP), an adder (carry chain), a memory (BRAM) and a register
// with sync reset and enable.
module top(input clk, input rst, input en, input [15:0] a, input [15:0] b,
           input [5:0] addr, input we, input [17:0] wd,
           output reg [31:0] p, output [16:0] s, output reg [17:0] rd, output reg [15:0] q);
    always @(posedge clk) p <= a * b;
    assign s = a + b;
    reg [17:0] mem [0:63];
    always @(posedge clk) begin
        if (we) mem[addr] <= wd;
        rd <= mem[addr];
    end
    always @(posedge clk) if (rst) q <= 16'd0; else if (en) q <= a;
endmodule
