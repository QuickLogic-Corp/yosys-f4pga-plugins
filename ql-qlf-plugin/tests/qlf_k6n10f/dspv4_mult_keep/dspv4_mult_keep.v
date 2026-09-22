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

// (* keep *) on the product. Fusing the adder into the DSP would delete that
// net, which is what the attribute asks synthesis not to do -- so the addition
// stays in fabric and the multiply still gets its DSP, driving the kept wire.
module dspv4_mult_keep (input signed [17:0] a, input signed [17:0] b,
                        input signed [40:0] c, output signed [40:0] s);
  (* keep *) wire signed [35:0] prod = a * b;
  assign s = prod + c;
endmodule
