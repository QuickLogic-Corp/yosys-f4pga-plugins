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

// Two IP instances plus one register of the user's own.
module top(input clk, input a, input b, output y0, output y1, output r);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0), .k());
    rel_ip u_ip1(.clk(clk), .d(b), .q(y1), .k());
    reg rr;
    always @(posedge clk) rr <= a & b;
    assign r = rr;
endmodule

// Only the IP has clocked logic, so the .clocks file depends on the IP's
// flip-flops alone.
module top_ip_only(input clk, input a, input b, output y0, output y1);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0), .k());
    rel_ip u_ip1(.clk(clk), .d(b), .q(y1), .k());
endmodule

// kk reads two IP outputs that are constant inside the IP.
module top_const(input clk, input a, input b, output y0, output y1, output kk);
    wire k0, k1;
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0), .k(k0));
    rel_ip u_ip1(.clk(clk), .d(b), .q(y1), .k(k1));
    assign kk = k0 ^ k1;
endmodule

// Nothing reads u_ip1: all its atoms are dead.
module top_dead(input clk, input a, input b, output y0);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0), .k());
    rel_ip u_ip1(.clk(clk), .d(b), .q(), .k());
endmodule

// Port-only stub that -rel_ip_blif replaces. It must be a blackbox, or
// hierarchy deletes it before the link step.
(* blackbox *)
module rel_ip(input clk, input d, output q, output k);
endmodule
