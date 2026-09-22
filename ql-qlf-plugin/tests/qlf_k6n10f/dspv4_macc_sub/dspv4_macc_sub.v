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

// Accumulate with a subtract: out <= out - a*b.
//
// P - A*B is the ALU's own subtract direction (Z - (W+X+Y)) over MULT_ACC's
// operand muxes, so it needs no extra hardware -- only the MULT_ACC_SUB control
// word, which the spreadsheet did not enumerate because it pairs ALUMODE=11
// with the A:B path rather than the multiplier path.
module dspv4_macc_sub (input clk, input rst, input signed [17:0] a,
                       input signed [17:0] b, output reg signed [35:0] p);
  // Synchronous reset: every DSP register bank resets synchronously, so an
  // async-reset accumulator cannot be absorbed at all and would test nothing.
  always @(posedge clk)
    if (rst) p <= 0; else p <= p - a * b;
endmodule
