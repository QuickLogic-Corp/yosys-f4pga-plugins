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

// C - A*B is MULT_SUB_C, the ALU's subtract direction. The operand order is
// deliberate: A*B - C is the reverse-subtract direction and a different mode
// (MULT_RSUB_C, see dspv4_mult_rsub_c), so swapping these would still infer a
// DSP and still count the same cells while negating the result.
module dspv4_mult_sub (input signed [17:0] a, input signed [17:0] b,
                       input signed [35:0] c, output signed [35:0] p);
  assign p = c - a * b;
endmodule
