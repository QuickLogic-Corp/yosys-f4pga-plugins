# DSP-V2 → DSP-V4 Mapping Reference (`ql_dspv2_to_dspv4`, Phase 1)

How the `ql_dspv2_to_dspv4` Yosys pass (`ql-dspv2-to-dspv4.cc`) rewrites each
generic `QL_DSPV2` hard-block cell (what Synplify Pro emits) into a generic
monolithic `QL_DSP4` base cell — which ports/signals move where, and how the
80-bit V2 `MODE_BITS` + control ports become the V4 configuration word.

- **Source of truth:** the DSP-V4 behavioural model `qlf_k6n10f/dspv4_sim.v`
  (`dsp4_top`); the V2 model `qlf_k6n10f/dspv2_sim.v` (`DSPV2IPG`).
- **Control words:** `DSPV4_SYNPLIFY_PHASE1_REQUIREMENTS.md`, Appendix A (per-cell
  + fused) and Appendix B (fusion latency).
- **Scope:** Phase 1 emits only the base `QL_DSP4` cell (no `QL_DSP4_*` subtypes).

> Two mappings below are flagged **⚠ PENDING** — they describe what the code does
> *today* but are known-incorrect and scheduled for fix (see
> [§8 Known issues](#8-known-issues--pending-corrections)). Everything else is the
> intended, verified mapping.

---

## 1. Cell interface: V2 ports → V4 ports/params

`QL_DSPV2` carries data on ports and config in the 80-bit `MODE_BITS` param plus
the `feedback`/`output_select` ports. `QL_DSP4` keeps **data / cascade / clock /
reset / clock-enable on ports** and moves the whole **control word to parameters**
(`OPMODE`, `ALUMODE`, `INMODE`, register-enables, …).

### 1.1 Data-path signals

| V2 port | width | → V4 | width | Notes |
|---|---|---|---|---|
| `a` | 31:0 | `A` | 31:0 | zero-extended to 32 |
| `b` | 17:0 | `B` | 17:0 | zero-extended to 18 |
| `c` (pre-adder operand) | 17:0 | `D` | 26:0 | **only** for `PREADDER_MULT`/`PREADDER_MULTADD`; else `D=0` |
| `z` (output) | 49:0 | `P` | 49:0 | the V2 `z` net becomes the V4 `P` output net |
| `z_cin` (cascade addend) | 49:0 | `PCIN` | 49:0 | only for a **genuine** `z`→`PCIN` cascade (per-cell MULTADD/PREADDER_MULTADD); else untied |
| `z_cout` (cascade output) | 49:0 | `PCOUT` | 49:0 | drives the dedicated cascade net so a downstream DSP's `PCIN` is fed (P1-FR-4); skipped if `z_cout` unconnected or same net as `z` |
| *(fused CONCAT `a`,`b`)* | — | `C` | 49:0 | fused addend `C = {A1[31:0], B1[17:0]}` (see §5) |

DSP-to-DSP product cascades (`stageN.z_cout → stageN+1.z_cin`) are reconnected as
`PCOUT → PCIN` on both per-cell and fused conversions (`connect_pcout`). In
`dspv2_sim.v` `z_cout_o == z_o` and in `dspv4_sim.v` `P == PCOUT`, so `PCOUT`
carries the same accumulated value; the downstream MULTADD's `Z=PCIN` OPMODE then
adds it.

### 1.2 Tied / unused inputs

Only genuinely-used inputs are connected. `CIN` is the one exception among the
"extra" inputs: it is an **active ALU carry-in** (selected by `CARRYINSEL=000`
and summed in the ALU), so it must be driven to `0`. Every input the current
config does *not* select is **left untied** (unconnected) rather than tied to 0.

| V4 port | Phase-1 connection | Reason |
|---|---|---|
| `CIN` | `0` | active ALU carry-in (`CARRYINSEL=000`) — must be driven |
| `C` | fused addend, else **untied** | per-cell modes never select C (OPMODE Z≠011) |
| `PCIN` | `z_cin` for a real cascade, else **untied** | selected only when OPMODE Z=PCIN |
| `D` | `c` for pre-adder modes, else **untied** | gated off by `INMODE[2]=0` otherwise |
| `ACIN`, `BCIN` | **untied** | A/B cascade chain out of Phase-1 scope |
| `CCIN`, `SIGNCIN` | **untied** | carry-/sign-cascade not selected (`CARRYINSEL=000`, Z≠MACC_EXT) |

Leaving an unselected input untied is safe: the OPMODE/`CARRYINSEL`/`INMODE`
muxes do not route it into the datapath, so its value cannot reach `P`.

### 1.3 Clocking / reset / clock-enable

| V2 | → V4 | Mapping | Notes |
|---|---|---|---|
| `clk` | `CLK` | direct | |
| `reset` (active-high) | `RSTN` (active-low, sync) | `RSTN = ~reset` | constant `reset` folds to a constant (no `$not` cell) |
| `acc_reset` (active-high) | `ACCRSTN` (active-low, sync) | `ACCRSTN = ~acc_reset` | synchronous accumulator clear (`l_rst_n_acc = RSTN & ACCRSTN`); may be dynamic |
| `load_acc` | — (must be constant) | — | DSP-V4 has **no dynamic accumulate-load**; see below |
| — | `ARSTN` | tied `1` | async reset inactive (Phase 1) |
| `load_acc` | `CEP` (accumulate modes) | `CEP = load_acc` (constant) | accumulator register enable: `1`=accumulate, `0`=hold |
| — | `CEA/CEB/CEC/CED` | tied `1` | per-stage CE gating not modelled |

**`load_acc` is the accumulator-register enable** (`1`=accumulate `acc←acc+A*B`,
`0`=hold), i.e. the enable of the V4 `P` register → **`CEP`**. It has no *dynamic*
DSP-V4 equivalent (V4 `CEP` is not a routable per-cycle input in Phase-1), so on an
accumulate mode (`MULTACC`/`MULTACC_NEG`) the pass **hard-errors if `load_acc` is
non-constant** (`require_const_load_acc`). When constant it is tied statically to
`CEP` (`CEP=1` → accumulate every cycle, `CEP=0` → hold). `acc_reset` maps to
`ACCRSTN` and may be dynamic. For non-accumulate modes `CEP` stays `1`.

---

## 2. V2 `MODE_BITS[79:0]` decode

Decoded in `decode_mode_bits()` (mirrors `dspv2_sim.v` / `ql_dspv2_types.cc`):

| Field | Bits | Field | Bits |
|---|---|---|---|
| `COEFF_0` | 31:0 | `A_SEL/A_REG/A1_REG/A2_REG` | 60/61/62/63 |
| `ACC_FIR` | 37:32 | `B_SEL/B_REG/B1_REG/B2_REG` | 64/65/66/67 |
| `ROUND` | 40:38 | `C_REG` | 68 |
| `ZC_SHIFT` | 45:41 | `BC_REG` | 69 |
| `ZREG_SHIFT` | 50:46 | `M_REG` | 70 |
| `SHIFT_REG` | 56:51 | `ZCIN_SEL` | 71 |
| `SATURATE` | 57 | `ACOUT_SEL` | 72 |
| `SUBTRACT` | 58 | `BCOUT_SEL` | 73 |
| `PRE_ADD` | 59 | `FRAC_MODE` | 79 |

Plus the two constant control ports: `feedback[2:0]`, `output_select[2:0]`
(resolved through VCC/GND driver cells). The **output register** is encoded in
`output_select[2]` (i.e. `output_select ≥ 4`) → `out_reg`.

---

## 3. Mode recognition (control word)

`control_word()` packs a recognition key, then `classify()` maps it to a mode:

```
control_word = feedback[2:0]<<5 | output_select[1:0]<<3 | ZCIN_SEL<<2 | PRE_ADD<<1 | SUBTRACT
```

| Control word (bin) | Mode |
|---|---|
| `00000000` | `MULT` |
| `00001000` | `MULTACC` |
| `00001001` | `MULTACC_NEG` |
| `00000010` / `00000011` | `PREADDER_MULT` (add / sub) |
| `01010000` / `01011000` | `CONCAT_CASCADE` |
| `01110100` / `01111100` | `MULTADD` |
| `01110101` / `01111101` | `MULTADD_NEG` |
| `01110110` / `01111110` | `PREADDER_MULTADD` |
| anything else | `UNKNOWN` → **hard error** |

---

## 4. Per-cell mode → V4 config word (Appendix A)

Common to all: `CARRYINSEL=000`, `USE_SIMD=00`. Signal remap `A←a, B←b, P→z,
D←c`. OPMODE is MSB-first `[8:0] = W[8:7] Z[6:4] Y[3:2] X[1:0]`.

| V2 mode | V4 function | OPMODE | ALUMODE | INMODE | AMULTSEL | BMULTSEL | PREADDINSEL | other |
|---|---|---|---|---|---|---|---|---|
| `MULT` | `A*B` | `000000101` | `00` | `00000` | 0 | 0 | 0 | — |
| `MULTACC` | `A*B+P` | `000100101` | `00` | `00000` | 0 | 0 | 0 | **PREG=1** |
| `MULTACC_NEG` | `P-A*B` | `000100101` | `11` | `00000` | 0 | 0 | 0 | **PREG=1** |
| `MULTADD`¹ | `A*B+PCIN` | `000010101` | `00` | `00000` | 0 | 0 | 0 | `PCIN←z_cin` |
| `MULTADD_NEG`¹ | `PCIN-A*B` | `000010101` | `11` | `00000` | 0 | 0 | 0 | `PCIN←z_cin` |
| `PREADDER_MULT` (add) | `(D+B)*A` | `000000101` | `00` | `00100` | 0 | 1 | 1 | `D←c` |
| `PREADDER_MULT` (sub) | `(D-B)*A` | `000000101` | `00` | `01100` | 0 | 1 | 1 | `INMODE[3]=1` |
| `PREADDER_MULTADD`¹ (add) | `(D+B)*A+PCIN` | `000010101` | `00` | `00100` | 0 | 1 | 1 | `PCIN←z_cin` |
| `PREADDER_MULTADD`¹ (sub) | `(D-B)*A+PCIN` | `000010101` | `00` | `01100` | 0 | 1 | 1 | `INMODE[3]=1` |

¹ Only when `z_cin` is a **real** DSP cascade (P1-FR-4). If `z_cin` is driven by a
`CONCAT_CASCADE`, the pair is **fused** instead (§5).

### 4.1 Why these OPMODEs (decode against `dsp4_top`)

`W=[8:7]{0,P,–,C}` · `Z=[6:4]{0,PCIN,P,C,MACC_EXT,PCIN»17,P»17}` ·
`Y=[3:2]{0,V,–,C}` · `X=[1:0]{0,U,P,A:B}`. The multiplier emits two partial
products **U** (sum) and **V** (=0), so `X=U, Y=V` reconstructs `A*B`.

| OPMODE | Z field | ALU expression |
|---|---|---|
| `000000101` | `000`→0 | `0 + U + V` = `A*B` |
| `000100101` | `010`→P | `P + U + V` = `A*B + P` (accumulate) |
| `000010101` | `001`→PCIN | `PCIN + U + V` = `A*B + PCIN` |
| `000110101` | `011`→C | `C + U + V` = `A*B + C` (fused) |

`ALUMODE`: `00` = `Z+(W+X+Y+CIN)` (add); `11` = `Z-(W+X+Y+CIN)` (subtract, giving
`P-A*B`, `PCIN-A*B`, `C-A*B`).

> **INMODE note.** The `INMODE` column above shows only the mode/pre-adder bits
> (`INMODE[2]`=D-active, `INMODE[3]`=pre-adder add/sub). The reg-path selects
> `INMODE[0]=A_REG` and `INMODE[4]=B_REG` (§6.1) are **OR-ed in** from the V2
> `MODE_BITS` of the same cell, so the emitted `INMODE` may set those bits too.

### 4.2 Pre-adder path (`PREADDER_*`)

`PREADDINSEL=1` routes `B` into the pre-adder; `BMULTSEL=1` feeds the pre-adder
result `AD` to the 18-bit multiplier port; `AMULTSEL=0` keeps `A` on the 32-bit
port. Result: `A * (D ± B)`. `INMODE[2]=1` gates `D` active; `INMODE[3]` selects
add(0)/sub(1). Matches `preadd_path`/`b_path` in `dspv4_sim.v`.

**MM-3 pre-adder overflow (accepted divergence, D12).** V2 computes `b + c` and
**saturates to signed 18-bit** (`dspv2_sim.v:1323-1343`). V4 computes `D ± B`,
saturates to 32-bit, then the 18-bit multiplier port takes `AD[17:0]` —
**truncated, no saturation** (`dspv4_sim.v`). So they agree only when the pre-add
sum fits signed-18 and diverge on overflow (V2 clamps, V4 wraps):

- **Guaranteed-equivalence range (confirmed):** `−131072 ≤ (b+c) ≤ 131071`
  (i.e. `D±B` fits signed-18). Within this range `a*(b+c)` is **bit-exact**; the
  pre-adder equivalence tests must bound their stimulus to it.
- **Example (overflow):** `b=c=100000` (each valid signed-18) → `b+c=200000`.
  V2 saturates → `131071` → `a·131071`. V4 truncates `200000[17:0]` → signed
  `−62144` → `a·(−62144)`. Divergent, but accepted (D12).

Non-pre-adder modes (`MULT`/`MULTACC`/`MULTADD`) have no pre-adder and are
bit-exact regardless of input.

---

## 5. Fused CONCAT_CASCADE + downstream (Appendix B)

When a `CONCAT_CASCADE` cell’s `z_cout` drives the `z_cin` of a `MULTADD` /
`MULTADD_NEG` / `PREADDER_MULTADD`, the pair collapses into **one** `QL_DSP4`
using the native 50-bit `C` input. Both source cells are removed.

- Downstream cell supplies `A←a, B←b, P→z` (and `D←c` for the pre-adder case).
- Upstream CONCAT supplies the addend: **`C = {A1[31:0], B1[17:0]}`** — CONCAT’s
  `a`→`C[49:18]`, CONCAT’s `b`→`C[17:0]`.
- `PCIN` is unused (`0`); the addend now travels via `C`.

| Fused pair | V4 function | OPMODE | ALUMODE | INMODE | BMULTSEL | PREADDINSEL |
|---|---|---|---|---|---|---|
| CONCAT + `MULTADD` | `A*B + C` | `000110101` | `00` | `00000` | 0 | 0 |
| CONCAT + `MULTADD_NEG` | `C - A*B` | `000110101` | `11` | `00000` | 0 | 0 |
| CONCAT + `PREADDER_MULTADD` (add) | `(D+B)*A + C` | `000110101` | `00` | `00100` | 1 | 1 |
| CONCAT + `PREADDER_MULTADD` (sub) | `(D-B)*A + C` | `000110101` | `00` | `01100` | 1 | 1 |

### 5.1 Fusion latency (`fusion_k`, Appendix B)

The V4 `C` path has a single register (`CREG`), so the addend delay must be
`k ≤ 1` or the pass **hard-errors** (no external balancing flops in Phase 1):

```
k = concat_in + concat_out + cons_zcin
  concat_in  = max(a_stages, b_stages) of the CONCAT   (input registers, PATH_OUT)
  concat_out = out_reg of the CONCAT (output_select[2]) (output register)
               [confirmed in dspv2_sim.v: output_select>=4 -> registered z1 on
                z_cout (:1544/:1548-1557); output_select<4 -> combinational]
  cons_zcin  = 0   (no verified MODE_BITS bit for an independent z_cin reg)
CREG = (k != 0)   → 0 or 1;   k >= 2 → HARD ERROR
```

`M_REG` is **not** part of `k`: it registers the *multiplier* output, and a
`CONCAT_CASCADE` does no multiply, so it cannot delay the A:B addend.

| CONCAT variant | delay | consumer `z_cin` reg | k | CREG | Verdict |
|---|---|---|---|---|---|
| `CONCAT_CASCADE` | 0 | 0/1 | 0/1 | 0/1 | **Fuse** |
| `CONCAT_CASCADE_REGIN` or `_REGOUT` | 1 | 0 | 1 | 1 | **Fuse** |
| `_REGIN`/`_REGOUT` + z_cin reg | 1 | 1 | 2 | — | **Hard-error** |
| `CONCAT_CASCADE_REGIN_REGOUT` | 2 | 0/1 | 2/3 | — | **Hard-error** |

---

## 6. Register mapping (internal V4 config, D9)

The A/B input registers are mapped by **reproducing the V2 operand register
*count*** on the V4 operand path — not by copying individual bits — because V4's
two enable bits are not per-stage. No external `DFFR` cells are produced.

### 6.1 A/B input registers (count → V4 encoding)

**Step 1 — count V2 stages** on the A operand from the three V2 register bits
(`a = A_REG ? r_a1 : (A1_REG&&A2_REG) ? r_a2² : A2_REG ? r_a2¹ : a`,
`dspv2_sim.v:1319`):

| V2 bits | A operand stages `n` |
|---|---|
| `A_REG` | 1 |
| `A1_REG && A2_REG` | 2 |
| `A2_REG` (only) | 1 |
| none | 0 |

**Step 2 — encode the same `n` on V4.** In `reg_path` (`dspv4_sim.v`) the operand
(`PATH_OUT`) delay is `(AREG0,AREG1) = (0,0)→0, (0,1)→1, (1,0)→0, (1,1)→2`, so:

```
AREG1 = (n >= 1)      AREG0 = (n >= 2)
```

B-path is identical (`b_stages` → `BREG0`/`BREG1`). `A_SEL→A_IN_SEL`,
`ACOUT_SEL→A_COUT_SEL` (and B mirrors) are still direct. **`INMODE[0]`/`INMODE[4]`
are left 0** — they steer the pre-adder `GATE_OUT` path, not the operand delay, so
they are *not* used to carry `A_REG`/`B_REG`; the `A_REG` contribution is folded
into the stage count instead.

> Why not a 1:1 bit copy? `(AREG0,AREG1)=(1,0)` gives **0** operand delay (the
> registered path is bypassed on the output mux), so copying `A1_REG→AREG0` for a
> single-register case would drop the stage. Counting stages and encoding
> `AREG1=(n≥1), AREG0=(n≥2)` reproduces the V2 latency exactly.

### 6.2 Other register params

| V4 param | Set from | Meaning |
|---|---|---|
| `MREG` | `M_REG` (bit 70) | multiplier-output register — applies only when the multiplier output is used (MULT / PREADDER_MULT and the product path of MACC/MADD); irrelevant to CONCAT |
| `DREG` | `C_REG` (bit 68) | pre-adder operand (`c`→`D`) register |
| `ADREG` | `BC_REG` (bit 69) | pre-adder **output** register (`dspv2_sim.v:1353` ≡ `dspv4_sim.v:520`) |
| `CREG` | `k` (fused) / 0 | addend register (fusion only, §5.1) |
| `PREG` | `accumulate ∨ out_reg` | accumulator register (accumulate modes) or the single V2 output register (non-accumulate) |
| `COUTREG` | `0` | not used in Phase 1 |

**Accumulate + output register (2 output-side stages).** A `MULTACC`/`MULTACC_NEG`
with the V2 output register (`output_select ≥ 4`) needs *both* the accumulator
register and an output register — 2 stages — but `PREG` only provides the
accumulator. The extra stage is materialised as an **external per-bit `dffre` on
`P`** (`add_output_dffre`, mirroring `ql_dspv2_types`' external Z register),
clocked from the V2 `clk`/`reset`. Non-accumulate `+out_reg` (e.g. `MULT`) needs
only one stage, handled by `PREG` internally (no external flop).

---

## 7. RSS + hard-error conditions

### 7.1 Round / shift / saturate (`set_rss_params`, P1-FR-13)

| V4 param | From V2 |
|---|---|
| `USE_RSS` | `1` if `ROUND≠0 ∨ SHIFT_REG≠0 ∨ SATURATE` |
| `ROUND[2:0]` | `ROUND` (bits 40:38) |
| `SHIFT[5:0]` | `SHIFT_REG` (bits 56:51) |
| `SATURATE` | `SATURATE` (bit 57) |

### 7.2 Hard errors (P1-FR-6, D10/D11)

The pass aborts (never silently approximates) on:

- **V2-only config** (no V4 analogue): `COEFF_0≠0`, `ACC_FIR≠0`, `FRAC_MODE=1`
  (16×9), `ZC_SHIFT≠0`, `ZREG_SHIFT≠0`. (MM-5 / MM-6)
- **`A_SEL` / `B_SEL` set** — selects the `a_cin`/`b_cin` cascade input
  (`dspv2_sim.v:1287-1288`); the A/B cascade chain is out of Phase-1 scope and
  `ACIN`/`BCIN` are untied, so this would select a floating input.
- **Non-constant `load_acc` on an accumulate mode** (`MULTACC`/`MULTACC_NEG`) —
  DSP-V4 has no dynamic accumulate-load control, so `load_acc` must be constant.
- **Non-constant** `feedback`/`output_select`.
- **Unrecognized / out-of-scope** mode (control word not in §3).
- **Lonely `CONCAT_CASCADE`** (no fusible consumer).
- **Non-reproducible fusion latency** `k ≥ 2` (§5.1).

---

## 8. Known issues / caveats

1. **`ROUND=5` (RHO) divergence (V2 model bug, not this pass).** `dspv2_sim.v` has a
   duplicate `3'b100` case (RHE and RHO), so `ROUND=101` is unreachable in the V2
   model (falls to "none") while V4 `round.v` implements RHO. Direct `ROUND` copy is
   correct for modes 0–4; equivalence at `ROUND=5` can't be trusted against the V2
   sim.

*(Resolved: `load_acc` → `CEP` (constant `load_acc=1`→accumulate, `0`→hold);
variable `load_acc`→hard-error; `acc_reset`→`ACCRSTN`; A/B input registers →
count-and-reproduce (§6.1). `load_acc` semantics confirmed to match `dspv2_sim.v`
— no model discrepancy. DSP-to-DSP cascade wired via `z_cout→PCOUT` (§1.1).
**Use-after-free fixed:** `QL_DSPV2` cell removal is deferred to the end of
`execute()` — removing cells mid-loop freed `RTLIL::Cell`s whose addresses Yosys
reused for newly-added `QL_DSP4`/`$not` cells, causing the pass to reprocess its
own output (netlist corruption, `PCIN=$undef`, spurious "unfusable CONCAT"
hard-errors, and crashes on the `*_wrap_shared` designs).)*

---

## 9. Worked examples

**`a*b` (MULT), no registers**
```
V2:  QL_DSPV2 #(.MODE_BITS(0)) (.a,.b,.z, feedback=0, output_select=0, ...)
V4:  QL_DSP4  #(.OPMODE(9'b000000101), .ALUMODE(0), .INMODE(0), .PREG(0), ...)
             (.A(a), .B(b), .P(z), .D(0), .C(0), .PCIN(0), CEx=1, RSTN=~reset, ...)
```

**`acc + a*b` (MULTACC)**
```
V2:  feedback=0, output_select=1, load_acc=1 (const)  (control word 0x08)
V4:  OPMODE=000100101 (Z=P), PREG=1, CEP=1;  P += A*B
     acc_reset -> ACCRSTN (~acc_reset);  variable load_acc -> hard error (§1.3)
```

**Fused `a*b + A1:B1` (CONCAT_CASCADE → MULTADD)**
```
V2:  CONCAT (feedback=2,os=2) .z_cout -> MULTADD (feedback=3,os=2,ZCIN_SEL=1) .z_cin
V4:  one QL_DSP4, OPMODE=000110101 (Z=C), C={A1[31:0],B1[17:0]}, CREG=k (0/1)
     both V2 cells removed
```

---

## 10. Source index

| What | File |
|---|---|
| The pass | `ql-dspv2-to-dspv4.cc` |
| V4 primitive (params→`dsp4_top`) | `QL_DSP4.v` — **owned by `device_data`** (D13); plugin copy is for unit tests only |
| V4 behavioural model (truth) | `dspv4_sim.v` — **owned by `device_data`** (D13); plugin copy is for unit tests only |
| V2 behavioural model (reference) | `dspv2_sim.v` — `device_data`-owned (same as V2) |
| Flow integration (`-dspv4`) | `synth_quicklogic.cc` (reads the libs from `family_path` = the `device_data` lib dir at flow time) |
| Control words / latency spec | `DSPV4_SYNPLIFY_PHASE1_REQUIREMENTS.md` App. A/B |
| Tests | `tests/qlf_k6n10f/dspv4*`, `.../dspv4_multacc_eqv/` |

> **`device_data` ownership (CASE 7 / D13).** The authoritative `QL_DSP4.v` and
> `dspv4_sim.v` ship via the `device_data` submodule (mirroring `dspv2_sim.v` /
> `QL_DSPV2.v`). The copies under `ql-qlf-plugin/qlf_k6n10f/` exist so the plugin's
> standalone unit tests can `read_verilog` them directly; the real `-synplify
> -dspv4` flow reads them from `device_data`. **Follow-up deliverable:** add them
> to the `device_data` `qlf_k6n10f` set (e.g. a `yosys-dspv4/…` dir) and keep the
> plugin copy in sync with that source of truth.
