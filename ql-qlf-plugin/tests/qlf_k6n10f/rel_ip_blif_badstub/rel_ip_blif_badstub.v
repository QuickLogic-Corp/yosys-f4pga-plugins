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

module top(input clk, input [1:0] a, output y0);
    rel_ip u_ip0(.clk(clk), .d(a), .q(y0));
endmodule

// The stub declares d as 2 bits; the IP netlist has a 1-bit d.
(* blackbox *)
module rel_ip(input clk, input [1:0] d, output q);
endmodule
