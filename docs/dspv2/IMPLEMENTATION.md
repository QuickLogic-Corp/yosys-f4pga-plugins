# DSPv2 Yosys-Plugin Implementation — 2026.2 Release

Companion to [REQUIREMENTS.md](REQUIREMENTS.md). Describes **what was actually implemented** on the `dspv2-yosys-initial-flow` branch and **how the implementation is verified**. Scope is MULT and 16x9 MULTACC inference for `qlf_k6n10f`; all deferred features are listed in REQUIREMENTS §3.4 / §8 K-SCOPE.

---

## 1. Implementation Overview

The DSPv2 inference path is opt-in via a new `-dspv2` switch on `synth_quicklogic` and reuses the existing v1 inference engines (`ql_dsp_macc`, `ql_dsp_simd`) augmented with a `-dspv2` mode. A new post-processing pass (`ql_dspv2_types`) reclassifies each generic `QL_DSPV2` cell into a subtype that downstream consumers (P&R, sim, reporting) can key off.

```
RTL ──► synth_quicklogic -dspv2 ──► ql_dsp_macc -dspv2 ──► techmap (mul2dsp + dsp_map.v -D DSPV2IPG)
                                                                                │
                                ◄────────── ql_dsp_simd -dspv2 ◄────────────────┘
                                                  │
                                                  ▼
                       techmap (dsp_final_map.v -D DSPV2IPG)  ──►  QL_DSPV2 cells
                                                  │
                                                  ▼
                                          ql_dspv2_types
                                                  │
                                                  ▼
                       QL_DSPV2_MULT  /  QL_DSPV2_MULTACC  (subtyped netlist)
```

---

## 2. Files Changed / Added

| Area | File | Change |
| --- | --- | --- |
| Pass plumbing | `ql-qlf-plugin/synth_quicklogic.cc` | Added `-dspv2` CLI flag; new `else if (!nodsp && dspv2)` branch invoking the v2 mapping chain; unconditional `run("ql_dspv2_types")` after the DSP branch. Fixed `dspv1_sim.v` → `dsp_sim.v` typo on the v1 path (R-SCRIPT-2 / D-3). |
| MACC inference | `ql-qlf-plugin/ql-dsp-macc.cc` + `ql-dsp-macc.pmg` | Added `-dspv2` flag; when set, lowers matched MACC patterns to a `QL_DSPV2` cell with the v2 80-bit `MODE_BITS` and `output_select_i` encoding instead of a `QL_DSP3` / `dsp_t1_*` cell. |
| SIMD packing | `ql-qlf-plugin/ql-dsp-simd.cc` | Added `-dspv2` flag; in v2 mode pairs half-width (`16x9`) `QL_DSPV2` cells into a single fractured `QL_DSPV2` instance. Equality check between halves excludes `FRAC_MODE` and `COEFF_0` only (K-SIMD-EXCLUDE). Guarded by `YS_HASHING_VERSION == 1` for Yosys API churn. |
| Subtype classification | `ql-qlf-plugin/ql_dspv2_types.cc` (new) | Implements the `ql_dspv2_types` pass. Iterates `QL_DSPV2` cells, inspects `MODE_BITS` / control ports, rewrites `cell->type` to one of the subtypes in §3 below. Silent no-op on v1 netlists (D-4). |
| Removed | `ql-qlf-plugin/ql-dsp-dspv2.cc`, `ql_dsp_dspv2.pmg` + Makefile entries | Dead code (never invoked from `synth_quicklogic`). Deleted per D-1. The upstream PR #4932 reference implementation will be re-imported when the post-2026.2 register-packing / cascading item is scheduled. |
| Collateral (external) | `qlf_k6n10f/QL_DSPV2.v`, `dspv2_sim.v`, `dsp_map.v`, `dsp_final_map.v` | Supplied by QuickLogic design team (D-5, K-DEP-COLLAT). The merged `dsp_map.v` carries both v1 and v2 module targets and is selected by `` `ifdef DSPV2IPG `` (D-2). **Status:** in-tree `dsp_map.v` currently has v1 targets only and lacks the v2 targets + guard — gating on the design-team drop (K-COLLAT-DSPMAP). |
| Tests | `ql-qlf-plugin/tests/qlf_k6n10f/dspv2_mult/`, `dspv2_macc/`, `dspv2_simd/`, `dspv2_types_v1_noop/` (new) + `tests/Makefile` | Four new tests covering positive inference, negative-rejection branches, SIMD packing, idempotency, and v1-noop contract. See §5. |

---

## 3. Pass-Level Behaviour

### 3.1 `synth_quicklogic -dspv2` (script)

Added DSPv2 branch in the `qlf_k6n10f` family block:

1. `wreduce t:$mul`
2. `ql_dsp_macc -dspv2` — extract MACC patterns into v2 `QL_DSPV2` cells.
3. Two `techmap` calls against `+/mul2dsp.v` + `dsp_map.v -D DSPV2IPG`:
   - 32x18 (`DSP_A_MAXWIDTH=32`, `DSP_B_MAXWIDTH=18`, `DSP_NAME=$__MUL32X18`)
   - 16x9 (`DSP_A_MAXWIDTH=16`, `DSP_B_MAXWIDTH=9`, `DSP_NAME=$__MUL16X9`)
   Both pass `-D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY`.
4. `ql_dsp_simd -dspv2` — pack two 16x9 halves into one fractured `QL_DSPV2`.
5. `techmap -map dsp_final_map.v -D DSPV2IPG` — finalise wrapper instantiation.
6. (Outside the DSP-branch) `ql_dspv2_types` — runs unconditionally; silent on v1.

`ql_dsp_io_regs -dspv2` is **not** invoked in 2026.2 release (K-SCOPE).

### 3.2 `ql_dspv2_types` subtype mapping

| Subtype | Cell-type after pass | Trigger |
| --- | --- | --- |
| Plain MULT | `QL_DSPV2_MULT` | `MODE_BITS` configured for multiply, accumulator path disabled. |
| MACC (16x9 only) | `QL_DSPV2_MULTACC` | `MODE_BITS` configured for multiply-accumulate; only the 16x9 variant is in scope. |

Register-variant subtypes (`_REGIN`, `_REGOUT`, `_REGIN_REGOUT`) are out of scope for 2026.2 release (K-SCOPE) and are explicitly asserted absent by the test suite.

---

## 4. Activation & Backward Compatibility

- `synth_quicklogic` (no flag) — runs the unchanged DSPv1 flow. `ql_dspv2_types` runs at the end but is a silent no-op (no `QL_DSPV2` cells exist). Enforced by `dspv2_types_v1_noop` test.
- `synth_quicklogic -dspv2` — runs the new v2 flow described above. Default-off; opt-in only.
- `synth_quicklogic -nodsp` — short-circuits both flows (unchanged).

No downstream consumer is affected unless it explicitly passes `-dspv2`.

---

## 5. Test Plan

All tests live in `ql-qlf-plugin/tests/qlf_k6n10f/` and run via `make -C ql-qlf-plugin/tests test_qlf_k6n10f` (or per-test `make … TESTS=<name>`). Each `<name>.tcl` begins with the canonical preamble:

```tcl
yosys -import
plugin -i ql-qlf
yosys -import
```

and invokes `synth_quicklogic -family qlf_k6n10f -top <design> -dspv2` (upstream pass name; see K-PASS-NAME for Aurora2 aliasing).

### 5.1 `dspv2_mult` — MULT inference

| Design | Asserts | Requirement |
| --- | --- | --- |
| `mult_32x18` (signed) | `1 t:QL_DSPV2_MULT` | R-MULT-1 |
| `mult_16x9` (signed) | `1 t:QL_DSPV2_MULT` | R-MULT-2 |
| `mult_20x18_s` | `1 t:QL_DSPV2_MULT` (fits 32x18) | R-MULT-1 (sizing) |
| `mult_8x8_s` | `1 t:QL_DSPV2_MULT` (fits 16x9 fractured) | R-MULT-2 (sizing) |
| All designs | `0 t:QL_DSPV2_MULTACC`, `0 t:QL_DSPV2` (unclassified), `0 t:QL_DSP2 t:QL_DSP3`, `0 t:dsp_t1_*` | D-7 + no v1 leakage |
| `test_dspv2_idempotent` | Two consecutive `ql_dspv2_types` runs produce identical cell counts | R-NFR-4 |

### 5.2 `dspv2_macc` — MULTACC inference (16x9, in-scope) + rejection

Accepted (→ `QL_DSPV2_MULTACC`):

| Design | Notes |
| --- | --- |
| `macc_16x9` | Baseline 16x9 MACC |
| `macc_16x9_sub` | Subtract-accumulate |
| `macc_16x9_en` | Clock-enable on accumulator |
| `macc_16x9_arst` | Async-reset on accumulator |

Rejected (must fall back to `QL_DSPV2_MULT` — outside MULTACC scope):

| Design | Reason |
| --- | --- |
| `macc_32x18` | Wider MACC deferred (K-SCOPE) |
| `macc_16x9_unsigned` | DSPv2 path is `DSP_SIGNEDONLY` |
| `macc_16x9_clearmux` | Synchronous-clear MACC variant deferred |

Helper proc `test_dspv2_macc <design> <expected_subtype>` asserts the expected subtype and `0` of the other.

### 5.3 `dspv2_simd` — SIMD packing

| Design | Asserts |
| --- | --- |
| `simd_mult_8x8` | `1 t:QL_DSPV2_MULT` (two halves packed) |
| `simd_mult_16x9` | `1 t:QL_DSPV2_MULT` |
| `simd_mult_three` | `2 t:QL_DSPV2_MULT` (one pair packed + one solo) |
| `simd_mismatched_clk` (negative) | `2 t:QL_DSPV2_MULTACC` (no packing across clock domains) |
| `simd_mult_keep_attr` (negative) | `2 t:QL_DSPV2_MULT` (`(* keep *)` blocks packing) |

Helper proc `test_dspv2_simd <design> <expected_mult> <expected_multacc>`.

### 5.4 `dspv2_types_v1_noop` — v1 backward-compatibility

Runs the **default** (no `-dspv2`) flow on `mult_20x18_s`, twice — once with and once without `-use_dsp_cfg_params`. Asserts:

- `1 t:QL_DSP2_MULT` (or `QL_DSP3_MULT`) — DSPv1 inference still works.
- `0 t:QL_DSPV2`, `0 t:QL_DSPV2_MULT`, `0 t:QL_DSPV2_MULTACC`, `0 t:QL_DSPV2_MULT_REGIN`, `0 t:QL_DSPV2_MULT_REGOUT`, `0 t:QL_DSPV2_MULT_REGIN_REGOUT` — `ql_dspv2_types` produces no spurious subtypes when no v2 cells are present (R-SCRIPT-4, D-4).

### 5.5 Coverage matrix

| Requirement | Covered by |
| --- | --- |
| R-MULT-1 (32x18 signed) | `dspv2_mult::mult_32x18`, `::mult_20x18_s` |
| R-MULT-2 (16x9 signed, fractured) | `dspv2_mult::mult_16x9`, `::mult_8x8_s`, all `dspv2_simd` positives |
| R-MACC-1 (16x9 MACC, signed) | `dspv2_macc` accepted set |
| R-MACC-NEG (rejection branches) | `dspv2_macc` rejected set |
| R-SIMD-1 (pack two 16x9 halves) | `dspv2_simd` positives |
| R-SIMD-NEG (no-pack conditions) | `dspv2_simd` negatives |
| R-TYPES-1 (subtype classification) | All four tests (via `0 t:QL_DSPV2` assertion) |
| R-SCRIPT-2 (correct sim file ref) | Implicit — build/regress fails otherwise |
| R-SCRIPT-4 (silent v1 no-op) | `dspv2_types_v1_noop` |
| R-NFR-4 (idempotency) | `dspv2_mult::test_dspv2_idempotent` |
| D-7 (assert on subtype, not generic) | All four tests |

### 5.6 Known coverage gaps

- **No post-synth arithmetic simulation** for the DSPv2 path (K-TEST-ARITH). Cell-count + subtype assertions only. A post-2026.2 follow-up should add `dspv2_mult_post_synth_sim` / `dspv2_simd_post_synth_sim` mirroring the existing v1 sim tests once the design-team `dspv2_sim.v` is in tree.
- **Tests are not executable in statically-linked Yosys builds** (K-TEST-ENV). Run only in the upstream CI conda env (`make env` → `source env/conda/bin/activate yosys-plugins` → `make test_ql-qlf`).

---

## 6. How to Run

```bash
# One-time: build a vanilla Yosys + plugin conda env
make env
source env/conda/bin/activate yosys-plugins

# Build & install the plugin
make plugins -j$(nproc)
make install

# Run the DSPv2 tests
make -C ql-qlf-plugin/tests \
     TESTS="dspv2_mult dspv2_macc dspv2_simd dspv2_types_v1_noop"

# Or the whole qlf_k6n10f suite (DSPv1 + DSPv2 + everything else)
make -C ql-qlf-plugin/tests test_qlf_k6n10f
```

A non-zero exit from any `select -assert-count` line fails the test.

---

## 7. Outstanding Work Before Release Tag

Gating items, in order:

1. **Design-team `dsp_map.v` drop** — install merged v1+v2 `dsp_map.v` with `` `ifdef DSPV2IPG `` guard (K-COLLAT-DSPMAP). Without this the `-dspv2` path will not lower `$mul` to a DSPv2 wrapper cell and **all four new tests will fail**.
2. **Design-team `QL_DSPV2.v` / `dspv2_sim.v` / `dsp_final_map.v` drop** — confirm bit-layout of the 80-bit `MODE_BITS` matches what `ql_dspv2_types` and the cfg-parameter emitters in `ql-dsp-macc.cc` / `ql-dsp-simd.cc` expect.
3. **CI run** of `make test_ql-qlf` in the upstream conda env — first end-to-end validation of the new tests (currently unverified locally; K-TEST-ENV).
4. **Tag** once items 1–3 are green.

Non-gating / post-2026.2:

- Port-wiring confirmation on `a_cout` / `b_cout` / `z_cout` (K-PORTS-CASCADE / D-6).
- Post-synth simulation tests (K-TEST-ARITH).
- Register-variant subtypes, wider MACC, cascading, pre-adder, MULTADD, `ql_dsp_io_regs -dspv2` (K-SCOPE).
