# Why the M-register match cannot compare the product signal exactly

Background for the `mff` match in `ql-dspv4.pmg` and its guards in `ql-dspv4.cc`.

The short version: **the register's `D` input is not the multiply's output — it
is the multiply's output wearing sign padding.** Matching them with an exact
signal comparison finds nothing, silently.

## The RTL

From `tests/designs/generic_verilog/gng/gng_smul_16_18_sadd_37.v` in aurora2:

```verilog
reg signed [15:0] a_reg;      // 16 bits
reg signed [17:0] b_reg;      // 18 bits
reg signed [33:0] prod;       // 34 bits = 16 + 18

always @(posedge clk) prod <= a_reg * b_reg;   // the register we want in the M bank
assign sum = c_reg + prod;
```

`prod` is declared 34 bits because a 16 x 18 multiply can need 34 bits. That is
the register we want to move into `QL_DSP4_M_DFFR_50` so the `c_reg + prod`
adder can fuse into the DSP's ALU.

## What the pattern originally asked for

"Find a flop whose `D` input **is** the multiply's output", written as an exact
`SigSpec` comparison:

```
index <SigSpec> port(mff, \D) === port(mul, \Y)
```

## The module on its own: matches

Nothing downstream, so `wreduce` has no reason to narrow the multiply and it
keeps all 34 bits:

```
   a_reg ──┐  ┌─────┐   Y[33:0]        D[33:0]  ┌──────┐  Q
           ├──┤ mul ├─────────────────────────► │ prod ├────►  + c_reg
   b_reg ──┘  └─────┘   34 bits        34 bits  └──────┘
                              └── same signal ──┘                 MATCH
```

`D` and `Y` are literally the same 34 wires. Synthesising this module alone
absorbs all five registers (`a_reg`, `b_reg`, `c_reg`, `prod`, `result`) **and**
fuses the adder — 9 cells, zero fabric flops, zero `adder_carry`.

## Inside the full gng design: does not match

In the whole design `wreduce` can see that the top 2 product bits never reach an
output, so it **narrows the `$mul` to 32 bits**. It does *not* narrow the `prod`
register, which stays 34 bits. The 2-bit gap is filled with copies of the sign
bit:

```
                         Y[31] ──────────────►  D[33]  ┐ sign
   a_reg ──┐  ┌─────┐    Y[31] ──────────────►  D[32]  ┘ padding
           ├──┤ mul ├── Y[31:0] ─────────────►  D[31:0]
   b_reg ──┘  └─────┘    32 bits               ┌──────┐  Q
                                               │ prod ├────►  + c_reg
                                               └──────┘
                                    D is 34 bits            NO MATCH
                                    Y is 32 bits
```

Same *number*, different *signal*. The exact comparison sees 34 bits versus 32
and rejects it before any other check runs — which is why the log said nothing
at all: the flop was never offered, so there was no rejection to report.

The diagnostic added to `ql-dspv4.cc` now says so directly:

```
product register $procdff$570 ($dff) not offered as an M stage
  -- D is 34 bits of a 32-bit product, CLK_POLARITY=1, product has 2 user(s)
```

Everything else was fine: right flop type (`$dff`), right clock edge, product
read exactly once. Only the width comparison failed.

Analogy: searching for `42` when the value is stored as `0042`.

## The fix

Stop requiring the signals to be identical. Anchor the index on a single bit,
then confirm the product sits in the bottom of `D` and the rest is padding:

```
   D[33:32] = padding    ──► ql-dspv4.cc checks these are copies of Y's top bit
   D[31: 0] = Y[31:0]    ──► the pattern checks this part matches exactly
```

```
index <SigBit> port(mff, \D)[0] === port(mul, \Y)[0]
filter GetSize(port(mff, \D)) >= GetSize(port(mul, \Y))
filter port(mff, \D).extract(0, GetSize(port(mul, \Y))) == port(mul, \Y)
```

The padding check lives in the pass rather than in a `filter` line because it
needs the multiply's signedness — sign-bit copies for a signed multiply, zeros
otherwise — and because `dspv4_strip_extension()` and friends are defined *after*
`#include "pmgen/ql-dspv4-pm.h"`, so the generated matcher cannot call them.

### Why absorbing the wider register is sound

The M bank and the ALU are 50 bits wide and sign-extend everything on the way
in. The padding `wreduce` left behind is exactly what the hardware would have
added by itself, so registering the full product and letting the DSP extend it
gives the same value:

```
   sext(sext(Y[31:0], 34), 50)  ==  sext(Y[31:0], 50)
```

If the bits above the product are *not* that padding — a concatenation with
unrelated data, say — the guard refuses.

### Why a failure refuses the whole fusion

If the M register cannot be absorbed, the pass returns `false` rather than
dropping just the register. `add` was indexed on this flop's `Q`, so the adder
being absorbed reads it. Keeping the adder while leaving the flop behind would
emit a DSP that adds the **unregistered** product, and delete the flop's only
reader along with it — a lost pipeline stage plus a stranded net. Refusing lets
pmgen offer the smaller shape instead: a bare `MULT` with the product register
in `P`.

## Related

The same "the operand is a transformed view of the product" problem appears in a
second disguise for wide-multiply cascade support: `mul2dsp` feeds its
partial-sum adder `{Y, 17'b0}` — the product shifted *left*, so the product bits
sit above rather than below. Worth handling with shared machinery rather than a
second special case.

`dspv4_strip_extension()` already does this job for the `A`/`B` operands. The
product side simply never got the same treatment.
