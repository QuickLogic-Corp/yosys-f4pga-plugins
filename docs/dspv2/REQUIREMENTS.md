# DSPv2 Yosys-driven Synthesis Inference — Requirements

**Document ID:** QL-PLUGIN-DSPV2-REQ-001
**Status:** Active
**Target family:** `qlf_k6n10f`
**Plugin:** `ql-qlf-plugin`
**Reference:** [YosysHQ/yosys#4932](https://github.com/YosysHQ/yosys/pull/4932) (povik/ql-dspv2)

---

## 1. Purpose

Enable a Yosys-driven DSPv2 inference flow under
`synth_quicklogic -family qlf_k6n10f -dspv2` **without** requiring the
`-synplify` switch. The flow infers `QL_DSPV2` cells from generic RTL
multiplies / multiply-accumulates / multiply-adds.

## 2. DSPv1 Preservation (hard requirement)

The V1 inference path shall remain **bit-identical** in behaviour. The
release is permitted to rename the V1 pass and pmg source files into a
`v1` namespace for symmetric naming with V2 (`ql-dsp.cc` → `ql-dspv1.cc`,
`ql_dsp.pmg` → `ql-dspv1.pmg`, registered pass `ql_dsp` → `ql_dspv1`).
No other V1 change is permitted.

## 3. Device-Data Convention (hard requirement)

Per-device Verilog files for `qlf_k6n10f` are owned by the Aurora
`device_data` submodule. **V1 and V2 devices ship their cell library
under the same filenames** — the per-device file *content* selects V1
vs V2 behaviour:

| Filename (same for V1 and V2) | Role |
|-------------------------------|------|
| `dsp_sim.v` | DSP simulation/cell-model library |
| `dsp_map.v` | DSP techmap (used by `mul2dsp` lowering) |
| `dsp_final_map.v` | Final-stage techmap (wrapper → hard cell) |

`synth_quicklogic.cc` therefore references the same filenames on both
the V1 and V2 arms. The plugin's own `ql-qlf-plugin/qlf_k6n10f/`
directory shall remain byte-identical to `origin/main`; the plugin does
not ship any V2-specific Verilog files of its own. `device_data`
overrides the plugin's shipped copies at install time.

## 4. Release Scope

### 4.1 In scope

| Item | Mechanism |
|------|-----------|
| `QL_DSPV2_MULT` (32×18 and 16×9) | `mul2dsp.v` + `dsp_map.v` (V2 content from `device_data`) |
| `QL_DSPV2_MULTACC` / `QL_DSPV2_MULTADD` | `ql_dspv2` pmgen patterns (`ql_dspv2_pack_regs`, `ql_dspv2_cascade`) |
| `_REGIN` / `_REGOUT` register absorption | `ql_dspv2_pack_regs` pmgen subpattern |
| Final collapse to `QL_DSPV2` | `dsp_final_map.v` (V2 content from `device_data`) |
| Subtype classification (`MULT` / `MULTACC` / `MULTADD` + `_REG*`) | `ql_dsp_io_regs` (V1 implementation, re-used unchanged) |

### 4.2 Deferred to a follow-up release

The following helper-pass extensions are **not** included in this
release. The V2 arm calls `ql_dsp_macc`, `ql_dsp_simd`, and
`ql_dsp_io_regs` with their V1 behaviour:

- `-dspv2` flag on `ql-dsp-macc.cc`
- `-dspv2` flag on `ql-dsp-simd.cc`
- `-dspv2` flag (a.k.a. `ql_dsp_io_regs_pass_v2()`) on `ql-dsp-io-regs.cc`
- DSPv2 test cases

This produces structurally-correct `QL_DSPV2` cells for the common
multiplier / MAC patterns. Subtype-classification fidelity on
V2-encoding-specific edge cases is tracked with the deferred
extensions.

### 4.3 Out of scope (no plan)

- ABC9 timing arcs for DSPv2
- Modifications to the Synplify-driven DSPv2 path (`ql_dspv2_types`
  pass remains untouched; it continues to handle Synplify input)
- Pre-adder / M-reg / bigger-adder / bigger-mult / A-cascade /
  B-cascade / chain-MAC inference

## 5. Functional Requirements

| ID | Requirement |
|----|-------------|
| **FR-1** | `synth_quicklogic -family qlf_k6n10f -dspv2` shall be accepted with or without `-synplify`. |
| **FR-2** | When `-dspv2` is set and `-synplify` is **not** set, the begin-label sim-load shall read `dsp_sim.v` (V2 content supplied by `device_data`). |
| **FR-3** | `QL_DSPV2.v` shall be read only on the Synplify path **without** `-dspv2` (i.e. `synplify && !dspv2`). The Yosys-driven V2 inference flow does not require an additional `QL_DSPV2.v` read. |
| **FR-4** | A new `ql_dspv2` pass shall be registered; its C++ body and pmg file are imported from PR #4932. The pass identifier is `ql_dspv2`; pmg pattern identifiers are `ql_dspv2_pack_regs` and `ql_dspv2_cascade`. The `-nocascade` flag is preserved. |
| **FR-5** | The V2 arm of `map_dsp` (for `qlf_k6n10f`, `!nodsp`, `dspv2`) shall execute: `wreduce t:$mul` → `ql_dsp_macc` → `techmap +/mul2dsp.v -map dsp_map.v` (32×18) → `chtype` → `techmap +/mul2dsp.v -map dsp_map.v` (16×9) → `chtype` → `ql_dspv2` → `ql_dsp_simd` → `techmap -map dsp_final_map.v` → `ql_dsp_io_regs`. |
| **FR-6** | The V1 arm of `map_dsp` shall be byte-identical to `origin/main`, except that the `qlf_k6n10` (non-`f`) branch invokes `ql_dspv1` (renamed from `ql_dsp`). |
| **FR-7** | The plugin's `ql-qlf-plugin/qlf_k6n10f/` directory shall not be modified relative to `origin/main`. |
| **FR-8** | The Makefile shall (a) add `ql-dspv1.cc` and `ql-dspv2.cc` to `SOURCES`, (b) add `ql-dspv1-pm.h` and `ql-dspv2-pm.h` to `DEPS`, and (c) add the corresponding pmgen recipes. `VERILOG_MODULES` shall be byte-identical to `origin/main`. |

## 6. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| **NF-1** | All existing V1 tests shall continue to pass unchanged. |
| **NF-2** | `-dspv2` without `-synplify` shall not affect synthesis of non-DSP logic. |
| **NF-3** | The plugin shall build on Linux (GCC 9+) and macOS (clang). |
