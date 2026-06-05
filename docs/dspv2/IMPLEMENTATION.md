# DSPv2 Yosys-driven Synthesis Inference — Implementation

**Document ID:** QL-PLUGIN-DSPV2-IMPL-001
**Status:** Active
**Requirements:** [REQUIREMENTS.md](REQUIREMENTS.md)
**Reference:** [YosysHQ/yosys#4932](https://github.com/YosysHQ/yosys/pull/4932)
**Branch:** `dspv2-partial-support` (from `origin/main`)

---

## 1. Change Inventory

| File | Action | Notes |
|------|--------|-------|
| `ql-qlf-plugin/Makefile` | edit | adds `ql-dspv1.cc` / `ql-dspv2.cc` SOURCES + pmgen recipes; `VERILOG_MODULES` unchanged |
| `ql-qlf-plugin/ql-dsp.cc` → `ql-qlf-plugin/ql-dspv1.cc` | rename + minor edit | pass `ql_dsp` → `ql_dspv1`, include `ql-dspv1-pm.h`; body otherwise identical |
| `ql-qlf-plugin/ql_dsp.pmg` → `ql-qlf-plugin/ql-dspv1.pmg` | rename + minor edit | pattern `ql_dsp` → `ql_dspv1`; fixes underscore-name outlier (hyphen branding) |
| `ql-qlf-plugin/ql-dspv2.cc` | **new** | byte-identical body to PR #4932 `ql_dsp.cc`; pass identifier suffixed `v2` |
| `ql-qlf-plugin/ql-dspv2.pmg` | **new** | byte-identical body to PR #4932 `ql_dsp.pmg`; patterns suffixed `v2` |
| `ql-qlf-plugin/synth_quicklogic.cc` | edit | drops Synplify-only V2 guard; gates `QL_DSPV2.v` read on `synplify && !dspv2`; adds V2 arm in `map_dsp`; `qlf_k6n10` arm pass call `ql_dsp` → `ql_dspv1` |
| `ql-qlf-plugin/qlf_k6n10f/**` | **untouched** | identical to `origin/main` — V2 device files come from `device_data` under the same `dsp_*.v` filenames |

No tests added in this release (see REQUIREMENTS.md §4.2).

## 2. `synth_quicklogic.cc`

### 2.1 Sim-library load (begin label)

```cpp
if (family == "qlf_k6n10f") {
    readVelArgs += family_path + "/dsp_sim.v";   // same filename for V1 and V2
    ...
}
...
run("read_verilog -lib -specify -nomem2reg " + readVelArgs);
if (synplify && !dspv2) {
    // QL_DSPV2.v is only needed by the Synplify path on V1 devices.
    run("read_verilog " + family_path + "/QL_DSPV2.v");
}
```

The V1-vs-V2 selection happens entirely at the `device_data` install
layer: each device's `qlf_k6n10f/dsp_sim.v` is either the V1 or the V2
cell-model file under the same filename.

### 2.2 `map_dsp` V2 arm

```cpp
if (dspv2) {
    // Helpers reused unchanged from V1 in this release; the V2-specific
    // -dspv2 extensions on ql_dsp_macc / ql_dsp_simd / ql_dsp_io_regs
    // are deferred (see REQUIREMENTS.md §4.2).
    //
    // Same dsp_*.v filenames on both arms per device_data convention.
    run("ql_dsp_macc");
    run("techmap -map +/mul2dsp.v -map " + lib_path + family + "/dsp_map.v "
        "-D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY "
        "-D DSP_A_MAXWIDTH=32 -D DSP_B_MAXWIDTH=18 "
        "-D DSP_A_MINWIDTH=10 -D DSP_B_MINWIDTH=10 "
        "-D DSP_NAME=$__MUL32X18");
    run("chtype -set $mul t:$__soft_mul");
    run("techmap -map +/mul2dsp.v -map " + lib_path + family + "/dsp_map.v "
        "-D USE_DSP_CFG_PARAMS=0 -D DSP_SIGNEDONLY "
        "-D DSP_A_MAXWIDTH=16 -D DSP_B_MAXWIDTH=9 "
        "-D DSP_A_MINWIDTH=4 -D DSP_B_MINWIDTH=4 "
        "-D DSP_NAME=$__MUL16X9");
    run("chtype -set $mul t:$__soft_mul");
    run("ql_dspv2");
    run("ql_dsp_simd");
    run("techmap -map " + lib_path + family + "/dsp_final_map.v");
    run("ql_dsp_io_regs");
}
```

Width thresholds (10×10 min for 32×18; 4×4 for 16×9), module names
(`$__MUL32X18`, `$__MUL16X9`), and the two-pass `mul2dsp` lowering are
verbatim from PR #4932.

### 2.3 `map_dsp` V1 arm

Byte-identical to `origin/main`, except for the renamed pass call on
the `qlf_k6n10` (non-`f`) branch (`ql_dsp` → `ql_dspv1`). All
`qlf_k6n10f` V1-arm techmap calls (`dsp_map.v`, `dsp_final_map.v`) and
helper-pass calls (`ql_dsp_macc`, `ql_dsp_simd`, `ql_dsp_io_regs`) are
unchanged from main.

## 3. `ql-dspv2.cc` / `ql-dspv2.pmg`

Imported byte-identical (modulo identifier renaming) from PR #4932's
`techlibs/quicklogic/ql_dsp.cc` and `ql_dsp.pmg`. Renames:

| #4932 | This plugin |
|-------|-------------|
| pass `ql_dsp` | `ql_dspv2` |
| C++ class `QlDspPass` | `QlDspv2Pass` |
| pmg pattern `ql_dsp_pack_regs` | `ql_dspv2_pack_regs` |
| pmg pattern `ql_dsp_cascade` | `ql_dspv2_cascade` |
| pmgen class `ql_dsp_pm` | `ql_dspv2_pm` |
| pmgen header `ql-dsp-pm.h` | `ql-dspv2-pm.h` |

The `-nocascade` flag is preserved verbatim. Both pmg patterns stay
active.

## 4. `ql-dspv1.cc` / `ql-dspv1.pmg`

Pure rename of `ql-dsp.cc` / `ql_dsp.pmg` (the latter also moves from
underscore to hyphen naming to match the rest of the plugin: `ql-dsp-*`,
`ql-bram-*`). Content edits:

- `Pass("ql_dsp", ...)` → `Pass("ql_dspv1", ...)`
- C++ class `QlDspPass` → `QlDspv1Pass` (helper functions / pm class
  consistently suffixed `v1`)
- `pattern ql_dsp` → `pattern ql_dspv1`
- `#include "pmgen/ql-dsp-pm.h"` → `#include "pmgen/ql-dspv1-pm.h"`

V1 inference behaviour is unchanged.

## 5. Makefile

```make
SOURCES = synth_quicklogic.cc \
-         ql-dsp.cc \
+         ql-dspv1.cc \
+         ql-dspv2.cc \
          ...

-DEPS := $(PMGEN_OUT_DIR)/ql-dsp-pm.h \
+DEPS := $(PMGEN_OUT_DIR)/ql-dspv1-pm.h \
+        $(PMGEN_OUT_DIR)/ql-dspv2-pm.h \
         $(PMGEN_OUT_DIR)/ql-dsp-macc.h \
         ...

-$(PMGEN_OUT_DIR)/ql-dsp-pm.h: ql_dsp.pmg
-       python3 $(PMGEN_PY) -o $@ -p ql_dsp ql_dsp.pmg
+$(PMGEN_OUT_DIR)/ql-dspv1-pm.h: ql-dspv1.pmg
+       python3 $(PMGEN_PY) -o $@ -p ql_dspv1 ql-dspv1.pmg
+
+$(PMGEN_OUT_DIR)/ql-dspv2-pm.h: ql-dspv2.pmg
+       python3 $(PMGEN_PY) -o $@ -p ql_dspv2 ql-dspv2.pmg
```

`VERILOG_MODULES` is **unchanged**: the plugin still ships `dsp_sim.v`,
`dsp_map.v`, `dsp_final_map.v` (and the V1 cell models) exactly as on
main. V2 cell content is supplied by `device_data` under the same
filenames at install time per REQUIREMENTS.md §3.

## 6. Commit Layout

Four commits on `dspv2-partial-support`:

1. `ql-qlf-plugin: rename v1 DSP namespace to ql_dspv1`
2. `ql-qlf-plugin: import DSPv2 pass from YosysHQ/yosys#4932`
3. `synth_quicklogic: drop Synplify-only -dspv2 guard; gate QL_DSPV2.v on synplify && !dspv2`
4. `synth_quicklogic: wire DSPv2 arm in map_dsp for qlf_k6n10f`

## 7. Validation

| Step | Status |
|------|--------|
| Plugin build (`make -j` against Aurora `dev/share/yosys`) | ✅ clean (macOS clang) |
| `ql-qlf-plugin/qlf_k6n10f/` diff vs `origin/main` | ✅ empty |
| V1 path code structure vs `origin/main` | ✅ rename-only delta |
| V2 pass body vs PR #4932 | ✅ byte-identical (modulo identifier suffix) |
| Aurora `tests/` smoke | pending submodule pin bump + run |

## 8. Workflow

- All edits land in the standalone clone at
  `Quicklogic-Corp/yosys-f4pga-plugins` on branch `dspv2-partial-support`
  cut from `origin/main`.
- After the plugin PR merges to `main`, the Aurora superproject's
  submodule pointer is bumped on a separate Aurora PR.
- No commits land in the nested submodule clone inside Aurora.
