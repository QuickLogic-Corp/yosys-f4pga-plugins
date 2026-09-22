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

// A*B - C, the reverse-subtract direction on the C port.
//
// The mirror of dspv4_mult_sub (C - A*B). The spreadsheet paired the
// reverse-subtract direction with the A:B bus only (RSUB_AB_C), never with the
// multiplier path, so this shape had no control word and stayed soft --
// MULT_RSUB_C supplies it.
module dspv4_mult_rsub_c (input signed [17:0] a, input signed [17:0] b,
                          input signed [35:0] c, output signed [35:0] p);
  assign p = a * b - c;
endmodule
