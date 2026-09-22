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

// A register between the multiply and the adder -- the DSP's M stage.
//
// This is the shape that had no home before MREG inference: the product is
// registered, then added combinationally, with no register on the result. The
// techmap used to fold a lone MREG onto the P register, which puts the ALU
// inside the registered path and so samples C a cycle early -- silently wrong.
// Now it gets the real M/MV/MK banks and the adder still fuses, so nothing is
// left in fabric.
module dspv4_mult_mreg (input clk,
                        input signed [17:0] a, input signed [17:0] b,
                        input signed [35:0] c,
                        output signed [36:0] p);
  reg signed [35:0] prod;
  always @(posedge clk) prod <= a * b;
  assign p = c + prod;
endmodule
