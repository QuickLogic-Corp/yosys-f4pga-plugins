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

// An async-reset accumulator cannot be absorbed.
//
// Every DSP register bank resets synchronously (dsp4_logical_map.v wires .R to
// RSTN on QL_DSP4_*_DFFRE_*), so there is nowhere in the DSP to put a flop that
// resets asynchronously. The multiply still becomes a DSP; only the accumulate
// stays outside, with the DSP's C port carrying the fabric value back in.
module dspv4_macc_areset (input clk, input rst, input signed [17:0] a,
                          input signed [17:0] b, output reg signed [35:0] p);
  always @(posedge clk or posedge rst)
    if (rst) p <= 0; else p <= p + a * b;
endmodule
