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

`default_nettype none
module sram1024x18 (
	clk_a,
	cen_a,
	wen_a,
	addr_a,
	wmsk_a,
	wdata_a,
	rdata_a,
	clk_b,
	cen_b,
	wen_b,
	addr_b,
	wmsk_b,
	wdata_b,
	rdata_b
);
	(* clkbuf_sink *)
	input wire clk_a;
	input wire cen_a;
	input wire wen_a;
	input wire [9:0] addr_a;
	input wire [17:0] wmsk_a;
	input wire [17:0] wdata_a;
	output reg [17:0] rdata_a;
	(* clkbuf_sink *)
	input wire clk_b;
	input wire cen_b;
	input wire wen_b;
	input wire [9:0] addr_b;
	input wire [17:0] wmsk_b;
	input wire [17:0] wdata_b;
	output reg [17:0] rdata_b;
	reg [17:0] ram [1023:0];

	integer i;

	always @(posedge clk_a) begin
		if (!cen_a) begin
	 		if (!wen_a)
				for (i = 0; i < 18; i++) begin
					if (!wmsk_a[i]) ram[addr_a][i] <= wdata_a[i];
				end
			rdata_a <= ram[addr_a];
		end
	end

	always @(posedge clk_b) begin
		if (!cen_b) begin
	 		if (!wen_b)
				for (i = 0; i < 18; i++) begin
					if (!wmsk_b[i]) ram[addr_b][i] <= wdata_b[i];
				end
			rdata_b <= ram[addr_b];
		end
	end

endmodule

