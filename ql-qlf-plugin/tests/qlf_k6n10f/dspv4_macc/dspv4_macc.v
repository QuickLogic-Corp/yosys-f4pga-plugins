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

// Reset to zero: the DSP accumulator resets to zero and cannot express any
// other reset value, so an unreset or non-zero-reset accumulator stays soft.
//
// The reset must also be SYNCHRONOUS. Every DSP register bank resets
// synchronously, so an async-reset accumulator cannot be absorbed -- see
// dspv4_macc_areset, which pins that. This test read `posedge clk or posedge
// rst` until 2026-09-10 and so left its accumulator in fabric while asserting
// only that $add was gone, which post-synth it is either way.
module dspv4_macc (input clk, input rst, input signed [17:0] a,
                   input signed [17:0] b, output reg signed [35:0] p);
  always @(posedge clk)
    if (rst) p <= 0; else p <= p + a * b;
endmodule
