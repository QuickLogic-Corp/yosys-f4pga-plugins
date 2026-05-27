# Requirements: DSPv2 Synthesis Support in `synth_quicklogic` (qlf_k6n10f, Yosys path)

Status: Draft for review
Branch under assessment: `dspv2-yosys-initial-flow` (PR #52)
Related upstream draft: YosysHQ/yosys#4932 (`povik/ql-dspv2`)

**Assumption / external dependency**: The authoritative DSPv2 device-side collateral (`QL_DSPV2.v`, `dspv2_sim.v`, `dsp_map.v`, `dsp_final_map.v` for `qlf_k6n10f`) is provided by the QuickLogic design team and supplied to this plugin as the canonical source of truth. This document does not assume any particular local filesystem location for that collateral; whenever the design team publishes an updated drop, the plugin's `qlf_k6n10f/` directory must be re-synchronised against it (scope `dsp_v2` only).

---

## 1. Background

QuickLogic's `qlf_k6n10f` family is moving from the legacy DSP block (v1, "DSP_T1": 20x18x64 / 10x9x32) to a new DSP block (v2, "QL_DSPV2": 32x18x64 / 16x9x32 fractured) that adds:

- a wider operand path (32x18 instead of 20x18),
- a dedicated pre-adder C input,
- explicit cascade ports (`a_cin/b_cin/z_cin` and `a_cout/b_cout/z_cout`),
- a separate synchronous accumulator-reset port (`acc_reset`) distinct from the asynchronous `reset`,
- a single configuration word (`MODE_BITS[79:0]`) instead of the v1 mix of control ports + coefficient parameters,
- subtype selection (MULT / MULTACC / MULTADD with various register-enable combos) driven post-mapping by the existing `ql_dspv2_types` pass.

The synthesis-tool collateral that the v2 block depends on is:

| Source | Role |
| --- | --- |
| `QL_DSPV2.v` | Blackbox model + fractured `dsp_type2_bw` body; defines the 80-bit `MODE_BITS` encoding. |
| `dspv2_sim.v` | Behavioural / subtype wrappers (`QL_DSPV2_MULT*`, `QL_DSPV2_MULTACC*`, `QL_DSPV2_MULTADD`). |
| `dsp_map.v` | techmap targets for the inference pass (`$__QL_MUL32X18`, `$__QL_MUL16X9`) that instantiate the two cfg-port wrappers. |
| `dsp_final_map.v` | techmap that lowers the cfg-port wrappers to `QL_DSPV2` and (for `DSPV2IPG`) to the subtype wrappers. |
| `cells_sim.v` | All non-DSP primitives (LUTs, FFs, IOs, etc.). |

PR #4932 (Yosys upstream, draft, by `@povik` / `@widlarizer`) adds an end-to-end DSPv2 flow built around three new/extended passes:

1. `ql_dsp_macc -dspv2` — extends the MACC pattern matcher to emit `dspv2_16x9x32_cfg_ports` cells.
2. `ql_dsp_simd -dspv2` — packs pairs of 16x9 halves into a single `dspv2_32x18x64_cfg_ports` cell with `FRAC_MODE=1`.
3. `ql_dsp` (renamed in this plugin as `ql_dsp_dspv2`) — performs A/B/Z register absorption ("pack_regs") and Z-path cascading ("cascade") on already-placed DSPv2 cells, with explicit half→full promotion.

PR #52 (this branch) is QuickLogic's first port of that upstream work into the standalone `yosys-f4pga-plugins/ql-qlf-plugin` so that the Yosys path can produce DSPv2 cells without depending on Synplify.

---

## 2. Goal

Replace the current `-dspv2 && !synplify ⇒ log_cmd_error` guard in `synth_quicklogic` with a working, well-tested Yosys-only **2026.2 release** DSPv2 inference and mapping flow for `qlf_k6n10f`, using the design-team-supplied device collateral (`QL_DSPV2.v`, `dspv2_sim.v`, `dsp_map.v`, `dsp_final_map.v`) as the authoritative source.

The DSPv1 path must continue to work unchanged for users that do not pass `-dspv2`.

**2026.2 release feature set** — strictly limited to two inference features (matches PR #52; see §3.4 for the explicit deferred list):

1. Basic multiplication inference (`MULT`), 32x18 and 16x9 widths. SIMD packing of two 16x9 halves into a single fractured 32x18 cell is treated as an internal implementation detail of MULT inference at 32x18 — it produces only `QL_DSPV2_MULT` subtype cells.
2. 16x9 multiply-accumulate inference (`MULTACC`).
3. Subtype classification of the resulting `QL_DSPV2` cells via `ql_dspv2_types`, restricted to the `QL_DSPV2_MULT` and `QL_DSPV2_MULTACC` subtypes.

All other DSPv2 features (wider MACC, register absorption, cascading, pre-adder, MULTADD, saturate/round/shift, IO-register packing, register-variant subtypes) are **explicitly deferred** — see §3.4.

---

## 3. Scope

### 3.1 In scope (2026.2 release)

- `synth_quicklogic` script for `family = qlf_k6n10f`, `-dspv2` branch — extend with the 2026.2 release feature set above.
- Modified passes inside `ql-qlf-plugin/`:
  - `ql_dsp_macc` — extend with `-dspv2` for the 16x9 MAC pattern only.
  - `ql_dsp_simd` — extend with `-dspv2` for fractured-pair packing.
  - `ql_dspv2_types` — already present; runtime placement reviewed (run unconditionally after `map_dsp`).
- Device-collateral files under `ql-qlf-plugin/qlf_k6n10f/`, scope `dsp_v2` only:
  - `QL_DSPV2.v` (sync with device folder — adds `(* blackbox *) (* keep *)` attributes and trailing newline),
  - `dspv2_sim.v` (sync with authoritative copy),
  - `dsp_map.v` (replace v2 inference targets; **keep** v1 targets behind a guard so v1 flow is unaffected),
  - `dsp_final_map.v` (add v2 lowerings + `DSPV2IPG` wrapper; **keep** v1 lowerings).
- Test targets under `ql-qlf-plugin/tests/qlf_k6n10f/`:
  - `dspv2_mult/`, `dspv2_macc/`, `dspv2_simd/` — basic functional checks.
- Plugin build (`Makefile`): source registration for the two extended passes.

### 3.2 Out of scope (this requirements document)

- DSPv1 inference / mapping behaviour — must remain bit-identical.
- The Synplify path through `synth_quicklogic`; only the failure-guard for `-dspv2 + Yosys` is removed.
- Any non-`qlf_k6n10f` family.
- BRAM, FF, IO, LUT mapping (the non-DSPv2 deltas the device folder also carries — `arith_map.v`, `cells_sim.v`, `bram*`, `synplify_*` — are handled by separate scopes and out of scope here).
- Place-and-route, openfpga arch updates, device fabric model.

### 3.3 Non-goals

- Functional equivalence with Synplify-produced netlists at the cell-name level; only structural / behavioural correctness against the simulation model is required.

### 3.4 Explicitly deferred DSPv2 features (post-2026.2)

These capabilities are present in upstream PR #4932 and/or partially scaffolded in this branch, but are **not part of the 2026.2 release**. They must be re-scoped as separate work items:

| Deferred feature | Current state in the branch | Note |
| --- | --- | --- |
| **32x18 MULTACC inference** | `ql_dsp_macc -dspv2` explicitly rejects ops wider than 16x9. | Wider MACs are inferred as MULT only; the accumulator FF stays in fabric. |
| **Register-variant MULT/MULTACC subtypes** (`_REGIN`, `_REGOUT`, `_REGIN_REGOUT`, `MULTACC_NEG`) | `ql_dspv2_types` can emit them, but no input/output FF absorption pass produces matching `MODE_BITS`. | 2026.2 release keeps external pipeline FFs in fabric. |
| **A_REG / B_REG / M_REG absorption** of external pipeline FFs | `ql_dsp_dspv2` pass from upstream PR #4932 implements `pack_regs`; **not ported** into this branch / 2026.2 release. | Removed (D-1). Re-import when scheduled. |
| **Z-path cascading + post-adder packing** (sum-of-products) | Same upstream pass owns `cascade`; not ported into 2026.2 release. | |
| **Pre-adder MULT** (`C` input — `(a + c) * b`) | `c_i` is tied to constant 0 everywhere; no inference pattern targets it. | `QL_DSPV2_PREADDER_MULT` subtype is recognised by `ql_dspv2_types` but unreachable. |
| **`QL_DSPV2_MULTADD[_NEG]` subtype** | Recognised by `ql_dspv2_types`, but no upstream pass produces matching MODE_BITS. | Requires cascading / post-adder support first. |
| **`ACC_FIR` / `SHIFT_REG` / `ROUND` / `SATURATE` / `ZC_SHIFT` / `ZREG_SHIFT`** | Tied to 0 on every emitted cell. | |
| **DSP I/O register absorption** (`ql_dsp_io_regs -dspv2`) | Pass exists; **not called** on the `-dspv2` branch (only on v1). | Required for full pipeline-register absorption parity with v1. |

---

## 4. User-Visible Behaviour

### 4.1 Command-line surface

`synth_quicklogic` flag set (qlf_k6n10f-only flags shown):

| Flag | Behaviour after this change |
| --- | --- |
| (none, default) | DSPv1 flow — unchanged from `main`. |
| `-dspv2` (Yosys) | Currently errors out; **after change**: runs the 2026.2 release DSPv2 inference + mapping flow described below. |
| `-dspv2` (Synplify) | Unchanged. |
| `-no_dsp` | Skip all DSP inference (both v1 and v2). |

No new top-level flags are introduced on `synth_quicklogic` itself.

Plugin-internal passes gain (2026.2 release):

- `ql_dsp_macc -dspv2`
- `ql_dsp_simd -dspv2`

(`ql_dsp_dspv2` is out of 2026.2 release scope — see §3.4.)

### 4.2 Output cell types

After a successful `synth_ql -family qlf_k6n10f -dspv2` run, the design must contain only:

- `QL_DSPV2` (post `dsp_final_map.v` lowering of `dspv2_*x*x*_cfg_ports`), and/or
- subtype wrappers produced by `ql_dspv2_types` — **in 2026.2 release scope, only `QL_DSPV2_MULT` and `QL_DSPV2_MULTACC` are expected to appear**. All other subtypes (register variants `..._REGIN`/`..._REGOUT`/`..._REGIN_REGOUT`, `QL_DSPV2_MULTACC_NEG`, `QL_DSPV2_PREADDER_MULT`, `QL_DSPV2_MULTADD[_NEG]`) are unreachable with the 2026.2 release pass set and their appearance in a 2026.2 release netlist indicates a regression.

No `dsp_t1_*`, `QL_DSP2`, or `QL_DSP3` cells may remain when `-dspv2` is used.

---

## 5. Functional Requirements

### 5.1 `synth_quicklogic` script

- **R-SCRIPT-1**: `-dspv2 + Yosys + qlf_k6n10f` must no longer abort with `log_cmd_error`.
- **R-SCRIPT-2**: Read-library step must pick the v2 simulation model (`dspv2_sim.v` + `QL_DSPV2.v`) when `-dspv2` is set, and the v1 simulation model (`dsp_sim.v`) otherwise. The path referenced for the v1 case must match the file actually present in `qlf_k6n10f/` (the branch currently references `dspv1_sim.v` which does not exist in the plugin — this discrepancy must be corrected to `dsp_sim.v` or the file renamed).
- **R-SCRIPT-3**: When `-dspv2` is set, the `map_dsp` label must execute (in order):
  1. `wreduce t:$mul`
  2. `ql_dsp_macc -dspv2`
  3. `techmap -map +/mul2dsp.v -map qlf_k6n10f/dsp_map.v -D DSPV2IPG -D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY -D DSP_A_MAXWIDTH=32 -D DSP_B_MAXWIDTH=18 -D DSP_A_MINWIDTH=10 -D DSP_B_MINWIDTH=10 -D DSP_NAME=$__MUL32X18`
  4. `chtype -set $mul t:$__soft_mul`
  5. `techmap -map +/mul2dsp.v -map qlf_k6n10f/dsp_map.v -D DSPV2IPG -D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY -D DSP_A_MAXWIDTH=16 -D DSP_B_MAXWIDTH=9 -D DSP_A_MINWIDTH=4 -D DSP_B_MINWIDTH=4 -D DSP_NAME=$__MUL16X9`
  6. `chtype -set $mul t:$__soft_mul`
  7. `ql_dsp_simd -dspv2`
  8. `techmap -map qlf_k6n10f/dsp_final_map.v -D DSPV2IPG`
- **R-SCRIPT-4**: `ql_dspv2_types` must run unconditionally after `map_dsp`, regardless of `-dspv2`/`-synplify`. (Matches commit 68a4cb9 in the branch.) When `-dspv2` is not set, the pass must be a no-op on the resulting netlist (it must not rewrite any `dsp_t1_*` / `QL_DSP2` / `QL_DSP3` cells).
- **R-SCRIPT-5**: `ql_dsp_dspv2`, `ql_dsp_io_regs -dspv2`, and any other DSPv2 register-packing / cascading / I/O-register passes are **out of 2026.2 release scope** (§3.4). The 2026.2 release script must not invoke them. Whether to ship the pass source as inert code or remove it pending the post-2026.2 work item is captured under D-1.

### 5.2 `ql_dsp_macc -dspv2`

- **R-MACC-1**: Match a MAC pattern `(z <= z [+/-] a*b)` driven by a single `$mul`, a single `$add`/`$sub`, an optional `$mux` (accumulator clear), and a single `$dff*` accumulator register.
- **R-MACC-2**: When `-dspv2` is in effect:
  - **R-MACC-2a**: Reject any unsigned multiplication (DSPv2 is signed-only). Rejected matches must fall through to the `mul2dsp` techmap path.
  - **R-MACC-2b**: Reject any match with a `$mux` (accumulator-clear pattern). DSPv2 cannot express dynamic feedback selection on the wrapper.
  - **R-MACC-2c**: Reject any operand wider than 9x16 or any Z wider than 25 bits. (Wider multiplies must be left for `mul2dsp + dsp_map.v` to lower into the wider `dspv2_32x18x64_cfg_ports` cell.)
  - **R-MACC-2d**: Emit a `dspv2_16x9x32_cfg_ports` cell, with:
    - `a_i`, `b_i` sign-extended to 16 / 9 bits respectively,
    - `z_o` zero-extended to 25 bits if narrower,
    - `c_i`, `a_cin_i`, `b_cin_i`, `z_cin_i` tied to constant 0 of the correct width,
    - `feedback_i = 3'b000` (no clear/load),
    - `output_select_i = 3'b001` (post-acc combinational output; see implementation doc for the rationale tied to `ql_dspv2_types::get_control_word`),
    - `reset_i = ARST` from an `$adff*`, otherwise 0,
    - `acc_reset_i = SRST` from an `$sdff*`, otherwise 0; reject `SRST_VALUE != 0`,
    - `load_acc_i = EN` from a `$dffe`/`$adffe`/`$sdffe`, otherwise 1,
    - parameter `FRAC_MODE = 1`, `SUBTRACT = 1` iff matched cell is `$sub`,
    - all other v2 cfg-parameters left at their wrapper defaults (must remain 0).
- **R-MACC-3**: When `-dspv2` is not in effect, behaviour must be byte-identical to current `main`.

### 5.3 `ql_dsp_simd -dspv2`

- **R-SIMD-1**: For each module, identify groups of `dspv2_16x9x32_cfg_ports` cells whose control-port connections and v2 cfg-parameters (excluding `COEFF_0` and `FRAC_MODE`) all agree, and pack consecutive pairs into a single `dspv2_32x18x64_cfg_ports` cell with `FRAC_MODE = 1`.
- **R-SIMD-2**: Data ports (`a_i`/`b_i`/`c_i`/`z_o`/`a_cin_i`/`b_cin_i`/`z_cin_i`/`a_cout_o`/`b_cout_o`/`z_cout_o`) of the two halves must be concatenated as `{high, low}` where `dsp_a` is the low half. Widths must match the wrapper definitions (16+16=32, 9+9=18, 25+25=50).
- **R-SIMD-3**: A v2 SISD candidate must be skipped (left as a 16x9 cell) if:
  - **R-SIMD-3a**: any bit of `a_cin_i`/`b_cin_i`/`z_cin_i` is driven by something other than constant 0/x (active cascade input), or
  - **R-SIMD-3b**: any bit of `a_cout_o`/`b_cout_o`/`z_cout_o` has at least one downstream consumer (active cascade output), or
  - **R-SIMD-3c**: any wire connected to one of its ports has the `(* keep *)` attribute.
- **R-SIMD-4**: When `-dspv2` is not in effect, behaviour must be byte-identical to current `main` (v1 SIMD packing of `dsp_t1_10x9x32_*` into `QL_DSP2`/`QL_DSP3`).

### 5.4 `ql_dsp_dspv2` (post-2026.2 — not required by this document)

The pass `ql_dsp_dspv2` (register absorption + Z-path cascading + post-adder packing) is **deferred to a follow-up requirements document**. The 2026.2 release must not invoke it from `synth_quicklogic`. The source files (`ql-dsp-dspv2.cc`, `ql_dsp_dspv2.pmg`) currently shipped by the branch are governed by D-1 below.

### 5.5 `ql_dspv2_types`

- **R-TYPES-1**: Existing behaviour (rewrite `QL_DSPV2` into `QL_DSPV2_MULT[_REGIN][_REGOUT]` / `QL_DSPV2_MULTACC[_REGIN][_REGOUT]` / `QL_DSPV2_MULTADD` subtypes based on the configuration word and on absorbed-vs-explicit input/output FFs) must be preserved.
- **R-TYPES-2**: The pass must run unconditionally in the script (R-SCRIPT-4) and must be a strict no-op on non-`QL_DSPV2` cells.

### 5.6 Collateral synchronisation with the device folder

- **R-COLLAT-1**: `ql-qlf-plugin/qlf_k6n10f/QL_DSPV2.v` must exist and match the design-team-supplied authoritative copy (defines the 80-bit `MODE_BITS` field layout consumed by `ql_dspv2_types`).
- **R-COLLAT-2**: `ql-qlf-plugin/qlf_k6n10f/dspv2_sim.v` must match the design-team-supplied authoritative copy (subtype wrappers).
- **R-COLLAT-3**: `ql-qlf-plugin/qlf_k6n10f/cells_sim.v` must be reconciled with the design-team drop. Differences that exist purely for plugin-side simulation (non-DSP) must be enumerated in the implementation document.
- **R-COLLAT-4**: `ql-qlf-plugin/qlf_k6n10f/dsp_map.v` must contain only the v2 techmap targets (`$__QL_MUL32X18`, `$__QL_MUL16X9`) when `DSPV2IPG` is defined, and must match the design-team-supplied file structurally. v1 targets (`$__QL_MUL20X18`, `$__QL_MUL10X9`) must remain available for the non-`-dspv2` path, guarded by `` `ifndef DSPV2IPG `` so a single merged file serves both flows (see D-2).
- **R-COLLAT-5**: `ql-qlf-plugin/qlf_k6n10f/dsp_final_map.v` must:
  - keep all existing v1 lowerings (`dsp_t1_*_cfg_ports`, `dsp_t1_*_cfg_params` → `QL_DSP2`/`QL_DSP3`) for the non-`-dspv2` path, and
  - add the v2 lowerings (`dspv2_32x18x64_cfg_ports`, `dspv2_16x9x32_cfg_ports` → `QL_DSPV2`) guarded by ``ifdef DSPV2IPG``, plus the `DSPV2IPG` wrapper that targets the subtype wrappers from `dspv2_sim.v`.
- **R-COLLAT-6**: The obsolete `qlf_k6n10f/dsp_sim.v` may be removed only once R-SCRIPT-2 is satisfied (no script path still references it). If kept, it must be unreferenced.

### 5.7 Plugin build

- **R-BUILD-1**: `Makefile` source list and pmgen rules must reflect the chosen disposition of `ql-dsp-dspv2.cc` / `ql_dsp_dspv2.pmg` (D-1). If the files are removed for 2026.2 release, the corresponding `SOURCES` and `DEPS` entries must be removed too; if they are kept dormant, the Makefile entries remain.
- **R-BUILD-2**: The build must continue to succeed for the existing Yosys version pinned by the plugin's CI; any new C++/Yosys API usage that requires a newer Yosys must be flagged in the implementation document.

---

## 6. Non-Functional Requirements

- **R-NFR-1 (regression safety)**: Existing `qlf_k6n10f` DSPv1 tests (`dsp_macc`, `dsp_madd`, `dsp_mult`, `dsp_simd`, `dsp_mult_post_synth_sim`, `dsp_simd_post_synth_sim`, `sim_dsp_*`) must continue to pass with identical assertions.
- **R-NFR-2 (test coverage)**: New `dspv2_mult` and `dspv2_macc` test directories must each assert that `synth_ql -dspv2` produces exactly the expected count of the appropriate subtype cell (`QL_DSPV2_MULT` / `QL_DSPV2_MULTACC`) for representative width / signedness combinations. A `dspv2_simd` test directory additionally validates that the SIMD-packing implementation detail of 32x18 MULT inference still yields `QL_DSPV2_MULT` cells (and no `QL_DSPV2_MULTACC` leakage).
- **R-NFR-3 (no Synplify regression)**: Synplify path through `synth_quicklogic` must remain unchanged.
- **R-NFR-4 (script idempotency)**: Running `synth_ql -dspv2` twice on the same RTL must produce equivalent netlists (same DSP count, same subtype distribution).
- **R-NFR-5 (logging)**: Each new pass must log a one-line summary per inferred / packed / cascaded cell, sufficient to diagnose missed inferences from a synthesis log.
- **R-NFR-6 (license / attribution)**: The new pass files `ql-dsp-dspv2.cc` and `ql_dsp_dspv2.pmg` are derived from YosysHQ/yosys#4932 (Apache-2.0 / ISC); attribution must be retained in the source header (already present in the branch).

---

## 7. Acceptance Criteria

1. `make -C ql-qlf-plugin` builds cleanly on the plugin's currently-pinned Yosys.
2. `make -C ql-qlf-plugin test TESTS=qlf_k6n10f` passes, including the three new `dspv2_*` directories.
3. All pre-existing `qlf_k6n10f` DSPv1 tests still pass.
4. `synth_quicklogic -family qlf_k6n10f -dspv2` on `tests/qlf_k6n10f/dspv2_mult/dspv2_mult.v` produces exactly one `QL_DSPV2_MULT` per top for `mult_32x18`, `mult_16x9`, `mult_20x18_s`, `mult_8x8_s`.
5. The same on `dspv2_macc.v` produces exactly one `QL_DSPV2_MULTACC` per top.
6. The same on `dspv2_simd.v` produces the SIMD-packed counts asserted in `dspv2_simd.tcl` (1, 1, 2 — each count refers to a single fractured `QL_DSPV2_MULT` cell after `ql_dspv2_types`).
7. No `dsp_t1_*` / `QL_DSP2` / `QL_DSP3` cells remain in the `-dspv2` netlists.
8. No new warnings on the DSPv1 (default) path.
9. Files in `ql-qlf-plugin/qlf_k6n10f/{QL_DSPV2.v, dspv2_sim.v, dsp_map.v, dsp_final_map.v}` match the authoritative copies supplied by the QuickLogic design team (scope `dsp_v2` only; non-DSPv2 deltas in the design-team drop are excluded — see the collateral-sync proposal in [`docs/dspv2/COLLATERAL_SYNC_PROPOSAL.md`](COLLATERAL_SYNC_PROPOSAL.md)).
10. No MULTACC inference is attempted for operand widths beyond 16x9; wider multiplies appear as standalone `QL_DSPV2_MULT` with the accumulator FF left in fabric (this confirms post-2026.2 scoping, §3.4).

---

## 8. Risks & Constraints

The list below reflects the **current state** of the `dspv2-yosys-initial-flow` branch after the cleanup pass. Items historically present but no longer applicable are kept in §9 (Decisions Log).

### Scope risks

- **K-SCOPE (feature gap vs upstream PR #4932 / DSPv1 parity)**: The 2026.2 release intentionally **excludes** wider MACC, register absorption (A_REG/B_REG/M_REG), register-variant subtypes (`_REGIN`/`_REGOUT`/`_REGIN_REGOUT`), `MULTACC_NEG`, Z-path cascading, post-adder packing, pre-adder MULT, MULTADD inference, ACC_FIR/shift/round/saturate, and `ql_dsp_io_regs -dspv2`. Users with pipelined-multiplier RTL will see external fabric FFs around the DSP rather than absorbed FFs. This is a known quality gap vs the v1 flow and vs upstream PR #4932; acceptable for 2026.2 release but must be tracked as a post-2026.2 work item.

### External-dependency risks (design team)

- **K-DEP-COLLAT**: Delivery of authoritative `QL_DSPV2.v`, `dspv2_sim.v`, `dsp_map.v`, `dsp_final_map.v` for `qlf_k6n10f` is an external dependency on the QuickLogic design team. The 2026.2 release **cannot ship a functional `-dspv2` path** without the design-team drop being installed in `ql-qlf-plugin/qlf_k6n10f/`. Changes to the 80-bit `MODE_BITS` layout or wrapper port set on the design-team side require a coordinated update of `ql_dspv2_types`, `ql-dsp-macc.cc`, and `ql-dsp-simd.cc`.
- **K-COLLAT-DSPMAP**: The current in-tree `qlf_k6n10f/dsp_map.v` contains **only the v1 targets** (`$__QL_MUL20X18`, `$__QL_MUL10X9`) and lacks the v2 targets (`$__QL_MUL32X18`, `$__QL_MUL16X9`) and the `` `ifdef DSPV2IPG `` guard required by R-COLLAT-4 / D-2. The synthesis script already passes `-D DSPV2IPG`, so once the design-team-supplied `dsp_map.v` (with v2 targets + guard) is dropped in, the `-dspv2` path will become functional. Until then, the `-dspv2` flow will fail to lower `$mul` to a `dspv2_*x*x*_cfg_ports` cell. **Sub-item of K-DEP-COLLAT; gating risk for the release.**
- **K-PORTS-CASCADE**: The design-team `QL_DSPV2.v` blackbox swaps `a_cout`/`b_cout`/`z_cout` port wiring inside the instantiation (`.z_cout(a_cout_o), .a_cout(b_cout_o), .b_cout(z_cout_o)`). This may be intentional bit-swap encoding or a device-file bug. Not blocking for 2026.2 release (no cascade path uses these ports — cascading is deferred per K-SCOPE) but must be resolved before any post-2026.2 cascading work item starts. **Needs QuickLogic design-team confirmation.**

### Implementation-coupling risks

- **K-MODEBITS**: `ql_dspv2_types`'s configuration-word interpretation (subtype classification, `output_select_i` decoding) is hard-coded against the v2 `MODE_BITS[79:0]` layout in `QL_DSPV2.v`. Any future change to that 80-bit encoding on the design-team side must be propagated into `ql_dspv2_types.cc` (and the cfg-parameter emitters in `ql-dsp-macc.cc` / `ql-dsp-simd.cc`).
- **K-SIMD-EXCLUDE**: `ql_dsp_simd -dspv2` excludes only `FRAC_MODE` and `COEFF_0` from the equality check when matching half-cells for packing. Any future cfg-parameter added to the v2 wrapper would silently block packing unless added to the exclude list.
- **K-YOSYS-VERSION**: The plugin already includes a `YS_HASHING_VERSION == 1` guard in `ql-dsp-simd.cc` for upstream API churn. Newer Yosys releases may require additional adaptations; the upstream-CI conda environment pins a specific Yosys SHA — bumping it requires re-validating both DSPv1 and DSPv2 paths.

### Verification-coverage risks

- **K-TEST-ARITH**: The DSPv2 test suite (`dspv2_mult`, `dspv2_macc`, `dspv2_simd`, `dspv2_types_v1_noop`) verifies cell counts, subtype classification, rejection branches, control-port equality, and idempotency — but does **not** include a post-synth simulation comparing inferred-DSPv2 output to the RTL reference (DSPv1 has `dsp_mult_post_synth_sim` / `dsp_simd_post_synth_sim`; DSPv2 has no equivalent). Arithmetic correctness against the design-team `QL_DSPV2.v` / `dspv2_sim.v` behavioural model is therefore not directly asserted. Tracked as a post-2026.2 follow-up.
- **K-TEST-ENV**: The plugin's tests rely on a vanilla Yosys built without ql-qlf statically linked. Downstream Aurora2 / VTR builds that statically link the plugin into Yosys will fail to load the freshly-built `.so` with "pass already exists" and cannot be used to run these tests; only the upstream CI conda environment (`make env` → `env/conda/bin/activate yosys-plugins`) is known to work for `make test_ql-qlf`.
- **K-PASS-NAME**: Tests invoke the synth pass as `synth_quicklogic` (the upstream plugin's registered name). The Aurora2 downstream build aliases this pass to `synth_ql` via `AURORA_YOSYS_SYNTH_PASS_NAME`; running these tests inside Aurora2's tree requires the upstream pass name to remain available, or a downstream-local alias adaptation.

---

## 9. Decisions Log

All decisions originally raised during requirements drafting have been **resolved** in the implementation. No items remain open at the time of this revision; the only externally-pending item (port-wiring confirmation) is tracked in §8 K-PORTS-CASCADE rather than here.

| # | Decision | Status |
| --- | --- | --- |
| D-1 | Disposition of the `ql_dsp_dspv2` pass source (`ql-dsp-dspv2.cc`, `ql_dsp_dspv2.pmg`) — never invoked from `synth_quicklogic` in the original branch. | **RESOLVED — removed.** Both files and their Makefile entries are deleted. Upstream PR #4932 implementation can be re-imported when the post-2026.2 register-packing / cascading work item is scheduled. |
| D-2 | Merge v1 + v2 into a single `dsp_map.v` (with `` `ifdef DSPV2IPG `` guards) or keep them as separate files. | **RESOLVED — single file with `` `ifdef DSPV2IPG ``**, to match the device-folder convention and minimise script changes. (The merged file is part of the design-team drop; see K-COLLAT-DSPMAP for the in-tree gating status.) |
| D-3 | Replace `dsp_sim.v` with `dspv1_sim.v` (rename) or fix the script reference. | **RESOLVED — kept `dsp_sim.v`** and corrected `synth_quicklogic.cc` (K-1 fix). |
| D-4 | Should `ql_dspv2_types` log when run on a v1 netlist? | **RESOLVED — silent skip.** Runs unconditionally per R-SCRIPT-4 but produces no log noise in v1 flows; the `dspv2_types_v1_noop` test enforces the silent no-op contract. |
| D-5 | Use the design-team-supplied `QL_DSPV2.v` / `dspv2_sim.v` / `dsp_map.v` / `dsp_final_map.v`, or keep in-plugin copies? | **RESOLVED — use the design-team-supplied drop** (scope `dsp_v2` only). Non-DSPv2 deltas handled per the collateral-sync proposal. |
| D-6 | Port-wiring swap in design-team `QL_DSPV2.v` — intentional or a bug? | **MOVED TO §8 K-PORTS-CASCADE.** Externally pending design-team confirmation; not an implementation decision and not blocking for 2026.2 release. |
| D-7 | Test assertions: count `t:QL_DSPV2` or the post-classification subtype? | **RESOLVED — count subtypes** (`t:QL_DSPV2_MULT` / `t:QL_DSPV2_MULTACC`) and additionally assert `0 t:QL_DSPV2` to catch un-classified cells. Tests also assert `0 t:QL_DSP2 t:QL_DSP3` / `0 t:dsp_t1_*` to guarantee no DSPv1 leakage on the `-dspv2` path. |

---

## 10. Deliverables

The implementation document (next step, written after this requirements document is approved) will cover:

1. Exact script ordering for `map_dsp` (with chosen answers to D-1 / D-2).
2. Exact `synth_quicklogic.cc` diff vs `main`.
3. File-by-file plan for `qlf_k6n10f/` collateral updates (D-2, D-3, D-5).
4. Per-pass code change list (`ql-dsp-macc.cc`, `ql-dsp-simd.cc`, `ql-dsp-dspv2.cc`, `ql_dsp_dspv2.pmg`, `ql_dspv2_types.cc`).
5. Makefile / pmgen / source-registration changes.
6. Test plan (additions, expected-cell-count updates per D-7).
7. Validation plan (DSPv1 regression matrix, DSPv2 functional matrix, post-synth sim if applicable).
8. Migration / rollout note: how to flip `-dspv2` on for downstream users (Aurora2, F4PGA flow).

---

## 11. References

- YosysHQ/yosys#4932 — "QuickLogic DSPv2 support" (draft, povik/widlarizer)
- QuickLogic-Corp/yosys-f4pga-plugins#52 — "DSPv2 initial Yosys synthesis flow" (this branch, draft)
- Branch under review: `dspv2-yosys-initial-flow` @ commits `75d3be0`, `ccd2517`, `68a4cb9`
- Authoritative DSPv2 device collateral: supplied separately by the QuickLogic design team (no in-repo path).
- In-tree files inspected: `ql-qlf-plugin/synth_quicklogic.cc`, `ql-dsp-macc.cc`, `ql-dsp-simd.cc`, `ql_dspv2_types.cc`, `qlf_k6n10f/dsp_map.v`, `qlf_k6n10f/dsp_final_map.v`, `qlf_k6n10f/QL_DSPV2.v`, `qlf_k6n10f/dspv2_sim.v`.
