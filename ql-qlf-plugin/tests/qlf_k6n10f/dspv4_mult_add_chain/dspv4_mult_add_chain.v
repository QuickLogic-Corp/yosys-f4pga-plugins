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

// A multiply-add chain three deep: two adders in series with no accumulator
// flop anywhere. This is the shape the cascade_* designs in the aurora2 DSP
// suite are built from.
module dspv4_mult_add_chain (input signed [17:0] a1, a2, a3, b,
                             output signed [37:0] p);
  wire signed [35:0] m1 = a1 * b;
  wire signed [36:0] s1 = a2 * b + m1;
  assign p = a3 * b + s1;
endmodule
