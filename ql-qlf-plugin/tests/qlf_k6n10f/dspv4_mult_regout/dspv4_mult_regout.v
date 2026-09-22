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

// A pipeline register on the product. The reset is synchronous: leaf R is
// driven from rstn_i (ACCRSTN for the accumulator) off the routable IC0 bus,
// so a synchronous reset is the only one the DSP can absorb. The register must
// end up in the DSP's accumulator bank, leaving no flop in fabric at all --
// that is the assertion with teeth.
module dspv4_mult_regout (input clk, rstn,
                          input signed [17:0] a, input signed [17:0] b,
                          output reg signed [35:0] p);
  always @(posedge clk)
    if (!rstn) p <= 0;
    else       p <= a * b;
endmodule
