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

// Direct instantiation of the GPIO v3.0 IO FF primitives (test-plan section 3,
// REQ-A1/REQ-A2/REQ-A4).
//
// This is the manual-instantiation escape hatch: it must work independently of
// ql_ioff promotion. The cells are instantiated in the middle of the design --
// D is not a top-level input and Q has fabric consumers -- so no boundary
// promotion is involved either way.

module direct_sdffr (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    input  wire other,
    output wire q_o
);
    wire d_int;
    wire q;

    assign d_int = d ^ other;
    assign q_o   = q & other;

    io_sdffr ff (
        .C(clk),
        .D(d_int),
        .R(rst_n),
        .Q(q)
    );
endmodule

module direct_sdffnr (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    input  wire other,
    output wire q_o
);
    wire d_int;
    wire q;

    assign d_int = d ^ other;
    assign q_o   = q & other;

    io_sdffnr ff (
        .C(clk),
        .D(d_int),
        .R(rst_n),
        .Q(q)
    );
endmodule
