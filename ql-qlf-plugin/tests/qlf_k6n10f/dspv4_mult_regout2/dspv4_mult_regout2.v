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

// Two pipeline register stages on the product, no adder.
//
// The DSP has two register positions between the multiplier and P -- the M bank
// and the ACC/P bank -- so both stages can come inside and nothing is left in
// fabric. Before MREG inference only the first stage was absorbed (as PREG) and
// the second stayed outside; Phase 3 records "output-register absorption beyond
// the single PREG stage" under Not attempted.
//
// This is vtr_bgm's mul_r2 shape. It does not help vtr_bgm itself, whose 24x24
// multiply is split across two DSPs by mul2dsp and so cannot absorb an output
// register at all, but it is the common two-stage pipeline otherwise.
module dspv4_mult_regout2 (input clk,
                           input signed [17:0] a, input signed [17:0] b,
                           output reg signed [35:0] p);
  reg signed [35:0] prod1;
  always @(posedge clk) prod1 <= a * b;
  always @(posedge clk) p     <= prod1;
endmodule
