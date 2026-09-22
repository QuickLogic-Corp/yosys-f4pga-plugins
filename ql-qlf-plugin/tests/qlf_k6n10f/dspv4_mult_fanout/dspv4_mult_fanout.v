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

// A product read by two adders. Neither addition can be fused -- the DSP has
// one P output and fusing either one would delete the net the other reads --
// but the MULTIPLY still belongs in a DSP.
//
// This used to infer nothing at all: the fanout guard sat in a `select` on the
// anchor `mul` match, which pmgen evaluates while building the candidate index,
// so the multiply was removed from the matcher and the `optional` fallback to a
// bare MULT never ran. The whole thing went to fabric as 599 LUTs, and the
// pass reported zero multiplies left soft.
module dspv4_mult_fanout (input signed [15:0] a, input signed [15:0] b,
                          input signed [31:0] c, input signed [31:0] d,
                          output signed [31:0] s1, output signed [31:0] s2);
  wire signed [31:0] prod = a * b;
  assign s1 = prod + c;
  assign s2 = prod + d;
endmodule
