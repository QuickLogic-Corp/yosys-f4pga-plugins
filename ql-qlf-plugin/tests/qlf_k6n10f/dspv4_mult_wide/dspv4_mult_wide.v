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

// A 48x32 multiply: four times wider than one cell's 32x18 ports can hold.
//
// ql_dspv4 alone leaves this as $mul and it goes to fabric whole -- 2952 LUTs.
// mul2dsp.v splits it into 32x18 pieces and a second ql_dspv4 pass puts each
// piece in a DSP. Four is the minimum: ceil(48/31) * ceil(32/17), the 31 and 17
// being what is left of each port once DSP_SIGNEDONLY takes its spare bit.
module dspv4_mult_wide (input signed [47:0] a, input signed [31:0] b,
                        output signed [79:0] p);
  assign p = a * b;
endmodule
