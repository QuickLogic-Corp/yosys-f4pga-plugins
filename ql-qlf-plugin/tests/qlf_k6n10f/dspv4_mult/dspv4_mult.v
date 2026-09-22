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

// Operands are signed: the DSP multiplier is signed, so an unsigned 18-bit
// value needs a spare bit and is left soft by design.
module dspv4_mult (input signed [17:0] a, input signed [17:0] b,
                   output signed [35:0] p);
  assign p = a * b;
endmodule
