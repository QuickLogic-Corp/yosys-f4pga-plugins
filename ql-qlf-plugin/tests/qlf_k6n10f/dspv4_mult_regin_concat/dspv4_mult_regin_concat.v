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

// An operand assembled from TWO registers rather than one.
//
// This is the shape the register walk used to be blind to. The lookup was keyed
// on a flop's ENTIRE Q, so a 16-bit operand made of two 8-bit registers matched
// nothing -- the registers were not refused, they were invisible, and the A bank
// stayed empty while B (a single whole register) absorbed normally. vtr_bgm
// absorbed nothing at all for this reason.
//
// Note the widths: both operands are far narrower than the 32/18-bit ports, so
// this also pins down that port width is NOT what decides absorption -- the
// operand's shape relative to one REGISTER is.
module dspv4_mult_regin_concat (input clk,
                                input signed [7:0] hi, input signed [7:0] lo,
                                input signed [7:0] b,
                                output reg signed [23:0] p);
  reg signed [7:0] hir, lor, br;
  always @(posedge clk) begin
    hir <= hi;
    lor <= lo;
    br  <= b;
  end
  always @(posedge clk) p <= $signed({hir, lor}) * br;
endmodule
