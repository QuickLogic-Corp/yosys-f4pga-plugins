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

(* blackbox *)
module gold(clk, a_a, rd_a, wd_a, we_a, a_b, rd_b, wd_b, we_b);

input wire clk;

input wire [ABITS-1:0] a_a;
output reg [DBITS-1:0] rd_a;
input wire [DBITS-1:0] wd_a;
input wire we_a;
input wire [ABITS-1:0] a_b;
output reg [DBITS-1:0] rd_b;
input wire [DBITS-1:0] wd_b;
input wire we_b;

endmodule

(* blackbox *)
module gate(clk, a_a, rd_a, wd_a, we_a, a_b, rd_b, wd_b, we_b);

input wire clk;

input wire [ABITS-1:0] a_a;
output reg [DBITS-1:0] rd_a;
input wire [DBITS-1:0] wd_a;
input wire we_a;
input wire [ABITS-1:0] a_b;
output reg [DBITS-1:0] rd_b;
input wire [DBITS-1:0] wd_b;
input wire we_b;
endmodule

module miter(in_clk, in_a_a, in_wd_a, in_we_a, in_a_b, in_wd_b, in_we_b);

input wire in_clk;

input wire [ABITS-1:0] in_a_a;
input wire [DBITS-1:0] in_wd_a;
input wire in_we_a;
input wire [ABITS-1:0] in_a_b;
input wire [DBITS-1:0] in_wd_b;
input wire in_we_b;

  wire [DBITS-1:0] gate_rd_a;
  wire [DBITS-1:0] gate_rd_b;

  wire [DBITS-1:0] gold_rd_a;
  wire [DBITS-1:0] gold_rd_b;

  rand const reg [ABITS-1:0] rand_addr;

  gate gate (
    .clk(in_clk),
    .a_a(in_a_a),
    .rd_a(gate_rd_a),
    .wd_a(in_wd_a),
    .we_a(in_we_a),
    .a_b(in_a_b),
    .rd_b(gate_rd_b),
    .wd_b(in_wd_b),
    .we_b(in_we_b)
  );
  gold gold (
    .clk(in_clk),
    .a_a(in_a_a),
    .rd_a(gold_rd_a),
    .wd_a(in_wd_a),
    .we_a(in_we_a),
    .a_b(in_a_b),
    .rd_b(gold_rd_b),
    .wd_b(in_wd_b),
    .we_b(in_we_b)
  );

  reg content_defined = 1'b0;

  always @(posedge in_clk) begin
    if(in_we_a && in_a_a == rand_addr) begin
      assume property (in_we_b |-> in_a_a != in_a_b); // no collision
      content_defined <= 1'b1;
    end
    if(in_we_b && in_a_b == rand_addr) begin
      assume property (in_we_a |-> in_a_a != in_a_b); // no collision
      content_defined <= 1'b1;
    end
    assert property (content_defined && (in_a_a == rand_addr) && !(in_we_b && in_a_b == rand_addr) |=> gold_rd_a == gate_rd_a);
    assert property (content_defined && (in_a_b == rand_addr) && !(in_we_a && in_a_a == rand_addr) |=> gold_rd_b == gate_rd_b);
    cover property (content_defined && (in_a_a == rand_addr) && !(in_we_b && in_a_b == rand_addr) ##1 gold_rd_a == gate_rd_a);
    cover property (content_defined && (in_a_b == rand_addr) && !(in_we_a && in_a_a == rand_addr) ##1 gold_rd_b == gate_rd_b);
  end
endmodule
