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

`include "params.vh"

module top(clk, a_a, rd_a, wd_a, we_a, a_b, rd_b, wd_b, we_b);

input wire clk;

input wire [ABITS-1:0] a_a;
output reg [DBITS-1:0] rd_a;
input wire [DBITS-1:0] wd_a;
input wire we_a;
input wire [ABITS-1:0] a_b;
output reg [DBITS-1:0] rd_b;
input wire [DBITS-1:0] wd_b;
input wire we_b;

(* syn_ramstyle = "block_ram" *)
reg [DBITS-1:0] mem [0:DEPTH-1];

always @(posedge clk) begin
	if(we_a) begin
		mem[a_a] <= wd_a;
	end
	rd_a <= mem[a_a];
	if (we_b && a_b == a_a) rd_a <= 'x;

end

always @(posedge clk) begin
	if(we_b) begin
		mem[a_b] <= wd_b;
	end
	rd_b <= mem[a_b];
	if (we_a && a_b == a_a) rd_b <= 'x;
end

endmodule
