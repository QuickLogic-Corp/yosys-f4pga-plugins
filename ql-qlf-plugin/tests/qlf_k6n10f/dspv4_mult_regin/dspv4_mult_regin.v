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

// Operand registers one deep on A and two deep on B. Each port has its own
// register stages inside the DSP, so each absorbs its own depth and nothing is
// left in fabric: A takes AREG1, B takes BREG0+BREG1. The DSP is not equalising
// delays, it is reproducing the ones the RTL asked for.
//
// The reset is synchronous because that is the only reset the DSP flops can
// take from fabric -- leaf R comes from rstn_i off the routable IC0 bus, while
// the async pin is chip-global with Fc = 0.
module dspv4_mult_regin (input clk, rstn,
                         input signed [17:0] a, input signed [17:0] b,
                         output signed [35:0] p);
  reg signed [17:0] a1, b1, b2;
  always @(posedge clk)
    if (!rstn) begin a1 <= 0; b1 <= 0; b2 <= 0; end
    else       begin a1 <= a;  b1 <= b;  b2 <= b1; end
  assign p = a1 * b2;
endmodule
