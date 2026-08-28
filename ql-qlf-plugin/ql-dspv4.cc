#include "kernel/sigtools.h"
#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

#include "dspv4_modes.inc"
#include "pmgen/ql-dspv4-pm.h"

// ============================================================================
// DSP-V4 inference.
//
// Turns generic RTL into QL_DSP4 cells directly -- no intermediate cell (IN-3).
// The techmap (dsp4_logical_map.v) then lowers each QL_DSP4 into dsp4_logical
// leaves, which is the same path Synplify and the ql_dspv2_to_dspv4 bridge take,
// so inference does not get its own lowering to keep in step.
//
// Control words are not written here. They come from dspv4_modes.inc, generated
// from dspv4_modes.yaml, which also drives the verification harness (CR-3): a
// mode this pass can emit is a mode verify_techmap.py checks.
//
// Scope is Phase 2: MULT, MULT_ADD_C, MULT_SUB_C, MULT_ACC and MULT_ACC_C
// (IN-5). Anything wider than 32x18 stays soft with a log_debug naming the cell
// (IN-7) -- a silent fallback to fabric is prohibited, because it looks like
// success and costs QoR.
// ============================================================================

// Look a mode up by name. A miss is a programming error rather than a user
// error: the names here are compiled in, so it means the table and this pass
// disagree about what exists.
static const Dspv4Mode &dspv4_mode(const char *name)
{
    for (size_t i = 0; i < DSPV4_MODE_COUNT; i++)
        if (!strcmp(DSPV4_MODES[i].name, name))
            return DSPV4_MODES[i];
    log_error("ql_dspv4: mode '%s' is not in dspv4_modes.inc.\n"
              "  The mode table is generated from dspv4_modes.yaml; regenerate\n"
              "  it with aurora2 scripts/dspv4/gen_mode_table.py.\n",
              name);
}

// Apply a mode's control word to a QL_DSP4 cell. Widths match the YAML's
// declared field widths, checked at generation time.
static void dspv4_apply_mode(RTLIL::Cell *cell, const Dspv4Mode &m)
{
    cell->setParam(ID(OPMODE), RTLIL::Const(m.opmode, 9));
    cell->setParam(ID(ALUMODE), RTLIL::Const(m.alumode, 2));
    cell->setParam(ID(INMODE), RTLIL::Const(m.inmode, 5));
    cell->setParam(ID(CARRYINSEL), RTLIL::Const(m.carryinsel, 3));
    cell->setParam(ID(USE_SIMD), RTLIL::Const(m.use_simd, 2));
    cell->setParam(ID(AMULTSEL), RTLIL::Const(m.amultsel, 1));
    cell->setParam(ID(BMULTSEL), RTLIL::Const(m.bmultsel, 1));
    cell->setParam(ID(PREADDINSEL), RTLIL::Const(m.preaddinsel, 1));
}


// Port widths on QL_DSP4. A is the 32-bit multiplier operand, B the 18-bit one.
static const int DSPV4_A_WIDTH = 32;
static const int DSPV4_B_WIDTH = 18;
static const int DSPV4_C_WIDTH = 50;
static const int DSPV4_P_WIDTH = 50;

// Operand register stages the DSP can hold (Phase 3, T3.2). This is the
// hardware limit, not a policy choice: AREG0 drives QL_DSP4_A1_DFFRE_32 and
// AREG1 drives A2_DFFRE_32, and there is no third stage.
static const int DSPV4_MAX_OPERAND_STAGES = 2;

// Distinct clock-enable signals a cell may use. The tile feeds all five CE pins
// from a 3-input crossbar (vpr.xml: `complete` on dsp.IC0[0..2] driving
// cea/ceb/cec/ced/cep), so a fourth enable has nowhere to route. ffb 4.2.5
// records this as a DRC because the mux sits outside the DSP RTL and is
// invisible to the cell's own definition.
static const int DSPV4_MAX_CE_SIGNALS = 3;

// C has ONE register stage (a single QL_DSP4_C_DFFRE_50), where A and B have two.
// A design that registers C more deeply keeps the surplus in fabric.
static const int DSPV4_MAX_C_STAGES = 1;

// Extend a signal to a port width, honouring the source cell's signedness.
// IN-9: operands narrower than the port are extended, not silently truncated.
static SigSpec dspv4_fit(RTLIL::Module *module, SigSpec sig, int width,
                         bool is_signed)
{
    if (GetSize(sig) > width)
        return sig.extract(0, width);
    sig.extend_u0(width, is_signed);
    (void)module;
    return sig;
}

// Strip an extension the RTL applied to an operand before the multiply.
//
// The register walk keys on a flop's exact Q, so an operand written as
// {1'b0, x} or {{n{x[msb]}}, x} hides the register behind a concat and the
// stage is never absorbed -- `a2 * $signed({1'b0, b2})` absorbs A's two stages
// and none of B's. The DSP re-applies the extension itself at the port width in
// dspv4_fit, so the design's copy is redundant.
//
// Signedness has to follow the strip. {1'b0, x} is precisely what makes an
// UNSIGNED x signed; dropping the zero while still calling the operand signed
// would turn a zero-extension into a sign-extension, and any value with its top
// bit set would read as negative. That is a wrong answer that no structural
// check would see, so the zero case forces is_signed false and lets dspv4_fit
// zero-extend it back.
static SigSpec dspv4_strip_extension(SigSpec sig, bool &is_signed)
{
    int n = GetSize(sig);
    if (n < 2)
        return sig;

    // Zero-extension: any run of constant zeros at the top, however short.
    if (sig[n - 1] == State::S0) {
        int i = n - 1;
        while (i > 0 && sig[i] == State::S0)
            i--;
        is_signed = false;
        return sig.extract(0, i + 1);
    }

    // Sign-extension: the top bits are copies of the value's own MSB, so one
    // copy is kept and the operand stays signed.
    SigBit top = sig[n - 1];
    if (top.wire == nullptr)
        return sig;                 // constant one-fill: not an extension
    int i = n - 2;
    while (i >= 0 && sig[i] == top)
        i--;
    if (i + 2 < n)
        return sig.extract(0, i + 2);
    return sig;
}

// Drive a design signal from a DSP output port that is wider than it. The port
// keeps its full width -- the techmap and the leaves expect 50 bits -- and only
// the low bits reach the design.
static SigSpec dspv4_wide_out(RTLIL::Module *module, SigSpec dst, int width)
{
    if (GetSize(dst) >= width)
        return dst.extract(0, width);
    SigSpec wide = module->addWire(NEW_ID, width);
    module->connect(dst, wide.extract(0, GetSize(dst)));
    return wide;
}

struct QlDspV4Pass : public Pass {

    QlDspV4Pass() : Pass("ql_dspv4", "Infer QL_DSP4 cells from generic RTL") {}

    void help() override
    {
        log("\n");
        log("    ql_dspv4 [options] [selection]\n");
        log("\n");
        log("Infers QL_DSP4 cells from multiply, multiply-add and accumulate\n");
        log("idioms. The cell is emitted with its control word already set;\n");
        log("dsp4_logical_map.v lowers it into the dsp4_logical leaves.\n");
        log("\n");
        log("Multiplies wider than 32x18 are left to soft logic and reported\n");
        log("with -verbose rather than silently dropped.\n");
        log("\n");
        log("    -verbose\n");
        log("        Report each inferred cell, and each multiply left soft.\n");
        log("\n");
    }

    bool replace_existing_pass() const override
    {
        return true;
    }

    void clear_flags() override { verbose = false; left_soft = 0; }

    void execute(std::vector<std::string> a_Args, RTLIL::Design *a_Design) override
    {
        log_header(a_Design, "Executing QL_DSPV4 pass.\n");

        size_t argidx;
        for (argidx = 1; argidx < a_Args.size(); argidx++) {
            if (a_Args[argidx] == "-verbose") {
                verbose = true;
                continue;
            }
            break;
        }
        extra_args(a_Args, argidx, a_Design);

        // T2.3 matches; T2.4 classifies and emits.
        int total = 0;
        for (auto module : a_Design->selected_modules()) {
            // `optional` makes pmgen enumerate both branches, so one $mul is
            // offered twice -- once with the adder and once bare. Emitting on
            // the first (larger) match and calling pm.autoremove() on the $mul
            // takes it out of the matcher, so the bare match never arrives.
            //
            // When the larger shape is refused -- an accumulator whose reset
            // value the DSP cannot express, say -- nothing is removed, and the
            // bare match then arrives and is emitted. That fallback is
            // deliberate: the multiply still gets a DSP and only the part that
            // cannot be expressed stays in soft logic.
            index_module(module);
            ql_dspv4_pm pm(module, module->selected_cells());
            pm.run_ql_dspv4([&]() {
                if (emit(pm, module))
                    total++;
            });
            for (auto ff : pending_removal)
                module->remove(ff);
            pending_removal.clear();
        }
        log("ql_dspv4: inferred %d QL_DSP4 cell(s), %d operand register "
            "stage(s) absorbed, %d multiply idiom(s) left soft.\n",
            total, absorbed_regs, left_soft);
    }

    // Map a matched shape to a mode name, or nullptr if this shape has no
    // multiply-form control word and must stay soft.
    const char *classify(ql_dspv4_pm &pm, bool feedback, std::string &why)
    {
        auto &st = pm.st_ql_dspv4;
        if (st.add == nullptr)
            return "MULT";
        if (feedback) {
            // The adder's other operand is the flop's own output, so this is an
            // accumulator rather than an add of an external value.
            if (st.add_is_sub) {
                why = "accumulate with a subtract has no Phase 2 control word";
                return nullptr;
            }
            // Two adders: the first took C, the second the feedback, so the DSP
            // computes A*B + P + C in one cell.
            return st.acc != nullptr ? "MULT_ACC_C" : "MULT_ACC";
        }
        if (!st.add_is_sub)
            return "MULT_ADD_C";
        // Operand order matters on subtract. C - A*B is MULT_SUB_C; A*B - C has
        // no multiply-form control word at all, so it stays soft rather than
        // being mapped to something that looks close.
        if (st.add_mul_port == ID(B))
            return "MULT_SUB_C";
        why = "A*B - C has no multiply-form control word (only C - A*B)";
        return nullptr;
    }

    bool emit(ql_dspv4_pm &pm, RTLIL::Module *module)
    {
        auto &st = pm.st_ql_dspv4;
        std::string why;

        // A matched flop is an accumulator only when its output comes back
        // round as the adder's other operand. Otherwise it is an ordinary
        // pipeline register on the result, which the DSP's P register can hold
        // just as well -- same register, different mode.
        bool feedback = st.ff != nullptr && st.add != nullptr &&
                        st.ff->getPort(ID::Q) == st.add->getPort(st.add_ba);

        const char *mode_name = classify(pm, feedback, why);

        // The `acc` slot is the C adder of the three-input MULT_ACC_C shape,
        // and that shape exists only when the chain ends in an accumulator
        // flop. Without the flop, a second chained adder is an ordinary
        // addition of its own: the DSP has one C port and no third input, so
        // there is nowhere to put it.
        //
        // Gating it here rather than in the pattern is deliberate -- pmgen
        // matches `acc` before `ff`, so the pattern cannot ask whether a flop
        // followed. Leaving it ungated made a plain two-deep adder chain fail
        // three ways at once: C was taken from the second adder (the wrong
        // operand), the second addition was never expressed because classify()
        // only reads `acc` under `ff`, and autoremove() deleted that adder
        // anyway -- leaving its result net with no driver at all.
        RTLIL::Cell *acc_cell = feedback ? st.acc : nullptr;

        // Which cell's output this DSP actually produces.
        RTLIL::Cell *out_cell = acc_cell != nullptr ? acc_cell
                              : st.add != nullptr   ? st.add : st.mul;
        SigSpec dsp_result = out_cell->getPort(ID::Y);

        // Absorb the flop only if it registers exactly that result.
        //
        // `ff` is indexed against `acc` when `acc` matched, so discarding
        // `acc` leaves `ff` sitting behind an adder this DSP does not
        // implement. Keeping it then drove the *later* stage's net from a DSP
        // computing the earlier stage -- a3*b + ma2_p never happened, p_out
        // took ma2_p's value, and ma2_p itself was left with no driver.
        //
        // Testing D against the result rather than special-casing that shape
        // keeps the rule true for every combination of the optional matches.
        RTLIL::Cell *ff_cell =
            (st.ff != nullptr && st.ff->getPort(ID::D) == dsp_result) ? st.ff
                                                                     : nullptr;

        // feedback is derived from st.ff, so a rejected flop must not leave a
        // mode that reads P back without the P register (CR-5). Unreachable as
        // the matches stand; refusing beats emitting a combinational loop.
        if (feedback && ff_cell == nullptr) {
            left_soft++;
            log_debug("  %s: left soft -- accumulator flop does not register "
                      "the DSP result\n", log_id(st.mul));
            return false;
        }

        if (mode_name == nullptr) {
            left_soft++;
            log_debug("  %s: left soft -- %s\n", log_id(st.mul), why.c_str());
            return false;
        }

        // Operand assignment and capacity.
        //
        // The multiplier is signed (Baugh-Wooley), so an UNSIGNED operand needs
        // a spare bit to stay positive: an 18-bit unsigned value with bit 17
        // set lands on the 18-bit B port and is read as negative. That is not a
        // corner case -- it is half of all random values, and it produces a
        // plausible wrong product rather than any kind of error.
        //
        // Hence capacity is the port width for a signed operand and one less
        // for an unsigned one. Try both assignments and take one that fits;
        // when both do, the wider operand goes to the 32-bit port.
        SigSpec ma = st.mul->getPort(ID::A), mb = st.mul->getPort(ID::B);
        bool a_signed = st.mul->getParam(ID::A_SIGNED).as_bool();
        bool b_signed = st.mul->getParam(ID::B_SIGNED).as_bool();

        auto fits = [](int w, bool sgn, int port) { return w <= (sgn ? port : port - 1); };
        bool direct = fits(GetSize(ma), a_signed, DSPV4_A_WIDTH) &&
                      fits(GetSize(mb), b_signed, DSPV4_B_WIDTH);
        bool swapped = fits(GetSize(mb), b_signed, DSPV4_A_WIDTH) &&
                       fits(GetSize(ma), a_signed, DSPV4_B_WIDTH);
        if (!direct && !swapped) {
            left_soft++;
            // Only mention the spare bit when it is actually what bit: saying
            // it for a signed x signed multiply sends the reader looking for a
            // signedness problem that is not there.
            bool unsigned_operand = !a_signed || !b_signed;
            log_debug("  %s: left soft -- %dx%d (%s x %s) does not fit the "
                      "%dx%d ports%s\n",
                      log_id(st.mul), GetSize(ma), GetSize(mb),
                      a_signed ? "signed" : "unsigned",
                      b_signed ? "signed" : "unsigned",
                      DSPV4_A_WIDTH, DSPV4_B_WIDTH,
                      unsigned_operand
                          ? "; the multiplier is signed, so an unsigned operand "
                            "needs a spare bit"
                          : "");
            return false;
        }
        if (!direct || (swapped && GetSize(mb) > GetSize(ma))) {
            std::swap(ma, mb);
            std::swap(a_signed, b_signed);
        }

        const Dspv4Mode &m = dspv4_mode(mode_name);
        RTLIL::Cell *cell = module->addCell(NEW_ID, ID(QL_DSP4));
        dspv4_apply_mode(cell, m);

        // C is the adder operand that is not the product. Present for
        // MULT_ADD_C / MULT_SUB_C, and for MULT_ACC_C where the first adder
        // takes C and the second takes the accumulator feedback. Plain MULT_ACC
        // has one adder whose other operand IS the feedback, so no C.
        // Where C comes from depends on the shape:
        //   MULT_ADD_C / MULT_SUB_C : `add`'s non-product operand
        //   MULT_ACC_C              : `acc`'s non-chain operand -- `add` holds
        //                             the accumulator feedback, not C
        //   MULT_ACC                : no C at all
        //
        // Determined here rather than at the point of use because C's register
        // chain takes part in the absorption decision below.
        bool acc = feedback;
        RTLIL::Cell *c_cell = acc_cell != nullptr ? acc_cell
                            : (st.add != nullptr && !acc) ? st.add : nullptr;
        IdString c_port = acc_cell != nullptr ? st.acc_ba : st.add_ba;
        SigSpec mc;
        bool c_signed = false;
        if (c_cell != nullptr) {
            mc = c_cell->getPort(c_port);
            c_signed = c_cell->getParam(
                c_port == ID::A ? ID::A_SIGNED : ID::B_SIGNED).as_bool();
            // A C operand wider than the port would be truncated by dspv4_fit,
            // which is a wrong answer rather than a missed optimisation. Refuse
            // the shape instead; the matcher then offers the bare multiply, so
            // the product still lands in a DSP and only the addition stays soft.
            if (GetSize(mc) > DSPV4_C_WIDTH) {
                left_soft++;
                log_debug("  %s: left soft -- %d-bit C operand exceeds the "
                          "%d-bit C port\n",
                          log_id(st.mul), GetSize(mc), DSPV4_C_WIDTH);
                module->remove(cell);
                return false;
            }
        }

        // Peel any extension the RTL applied, so the walk below can see the
        // flop behind it. Both the port value and its signedness are updated,
        // and dspv4_fit re-extends to the port width when the ports are set.
        ma = dspv4_strip_extension(ma, a_signed);
        mb = dspv4_strip_extension(mb, b_signed);

        // T3.1 / T3.2 -- absorb the designer's registers.
        //
        // Each operand port has its OWN register stages inside the DSP:
        // AREG0/AREG1 for A, BREG0/BREG1 for B, a single CREG for C, and the
        // accumulator bank for P. dsp4_logical_map.v gates them in independent
        // generate blocks, so each port absorbs its own RTL depth and any
        // surplus stays in fabric. The DSP is not equalising delays -- it is
        // reproducing the relative delays the RTL asked for, so a design that
        // registers A and B twice and C once maps exactly, skew included.
        //
        // What the ports DO share is CLK and RSTN, so every absorbed chain has
        // to agree on both. Enables are per-port (CEA / CEB / CEC / CEP) and
        // need not agree -- but at most three distinct enable signals can reach
        // the cell, see the eviction loop below.
        int na = 0, nb = 0, nc = 0;
        FlopChain ca, cb, cc;
        {
            bool seeded = ff_cell != nullptr;
            SigSpec seed_clk, seed_rst(State::S1);
            bool seed_rst_inv = false;
            if (seeded) {
                seed_clk = ff_cell->getPort(ID(CLK));
                if (ff_cell->hasPort(ID(SRST))) {
                    seed_rst = ff_cell->getPort(ID(SRST));
                    seed_rst_inv =
                        ff_cell->getParam(ID(SRST_POLARITY)).as_bool();
                }
            }
            ca = collect_flops(module, ma, DSPV4_MAX_OPERAND_STAGES, seed_clk,
                               seed_rst, seed_rst_inv, seeded);
            cb = collect_flops(module, mb, DSPV4_MAX_OPERAND_STAGES, seed_clk,
                               seed_rst, seed_rst_inv, seeded);
            if (c_cell != nullptr) {
                cc = collect_flops(module, mc, DSPV4_MAX_C_STAGES, seed_clk,
                                   seed_rst, seed_rst_inv, seeded);
                // A flop on the C path whose D is this shape's OWN result is
                // the accumulator feedback, not an independent C operand.
                // pmgen offers the match without the output flop too, and on
                // that branch `feedback` is false, so an accumulator looks
                // exactly like a plain add of a registered value. Absorbing it
                // deletes the register the design accumulates into and leaves
                // the output undriven -- the whole design then sweeps away as
                // dead logic, which synthesis reports as success.
                for (auto f : cc.flops) {
                    if (sigmapper(f->getPort(ID::D)) == sigmapper(dsp_result)) {
                        cc.flops.clear();
                        break;
                    }
                }
            }
            na = GetSize(ca.flops);
            nb = GetSize(cb.flops);
            nc = GetSize(cc.flops);

            // Shared CLK and RSTN: a chain that disagrees with another absorbed
            // chain on either cannot go in. Compared as raw signal plus
            // polarity, never as resolved inverter outputs -- comparing those
            // is what once made every active-high reset absorb nothing.
            auto agrees = [&](const FlopChain &x, const FlopChain &y) {
                return same(x.clk, y.clk) && same(x.arst, y.arst) &&
                       x.arst_inv == y.arst_inv;
            };
            if (na > 0 && nb > 0 && !agrees(ca, cb))
                nb = 0;
            if (nc > 0 && na > 0 && !agrees(ca, cc))
                nc = 0;
            if (nc > 0 && nb > 0 && !agrees(cb, cc))
                nc = 0;
        }

        // Clock-enable crossbar. The tile feeds all five CE pins from a 3-input
        // mux (vpr.xml: `complete` on dsp.IC0[0..2] -> cea/ceb/cec/ced/cep), so
        // a fourth distinct enable has nowhere to route. ffb 4.2.5 records it as
        // a DRC because the mux sits outside the DSP RTL.
        //
        // Give up the narrowest port first: a wider port saves more fabric
        // flops, so it is the one worth keeping. Eviction is per-port and
        // all-or-nothing -- dropping one stage of a two-deep port still needs
        // that port's enable, so it saves no slot.
        //
        // P is never evicted. In a feedback mode the techmap rejects the cell
        // outright when USES_P && !PREG, so giving up the accumulator does not
        // move a flop to fabric -- it makes the whole multiply soft. Its 50-bit
        // width would put it last anyway; this makes that explicit.
        {
            auto distinct_enables = [&]() {
                std::vector<SigSpec> seen;
                auto note = [&](const SigSpec &sig) {
                    if (sig.is_fully_const())
                        return;             // a tied enable needs no signal
                    for (auto &t : seen)
                        if (t == sig)
                            return;
                    seen.push_back(sig);
                };
                if (na > 0)
                    note(ca.en);
                if (nb > 0)
                    note(cb.en);
                if (nc > 0)
                    note(cc.en);
                if (ff_cell != nullptr && ff_cell->hasPort(ID(EN)))
                    note(ff_cell->getPort(ID(EN)));
                return GetSize(seen);
            };
            // Narrowest first: B (18), A (32), C (50). P (50) is not a
            // candidate.
            struct Evictee { int *n; const char *name; int width; };
            const Evictee order[] = {
                {&nb, "B", DSPV4_B_WIDTH},
                {&na, "A", DSPV4_A_WIDTH},
                {&nc, "C", DSPV4_C_WIDTH},
            };
            for (auto &e : order) {
                if (distinct_enables() <= DSPV4_MAX_CE_SIGNALS)
                    break;
                if (*e.n == 0)
                    continue;
                log_debug("  %s: %s registers left in fabric -- the cell would "
                          "need more than %d distinct clock enables, and %s is "
                          "the narrowest port at %d bits\n",
                          log_id(st.mul), e.name, DSPV4_MAX_CE_SIGNALS, e.name,
                          e.width);
                *e.n = 0;
            }
        }

        if (na > 0)
            ma = ca.flops[na - 1]->getPort(ID::D);
        if (nb > 0)
            mb = cb.flops[nb - 1]->getPort(ID::D);

        cell->setPort(ID::A, dspv4_fit(module, ma, DSPV4_A_WIDTH, a_signed));
        cell->setPort(ID::B, dspv4_fit(module, mb, DSPV4_B_WIDTH, b_signed));

        // With a flop absorbed the DSP drives its Q directly; the
        // combinational result never appears in the netlist at all.
        SigSpec result = ff_cell != nullptr ? ff_cell->getPort(ID::Q)
                                            : dsp_result;

        if (c_cell != nullptr) {
            if (nc > 0)
                mc = cc.flops[nc - 1]->getPort(ID::D);
            cell->setPort(ID(C), dspv4_fit(module, mc, DSPV4_C_WIDTH, c_signed));
        }

        cell->setPort(ID(P), dspv4_wide_out(module, result, DSPV4_P_WIDTH));

        // Operand register stages. The encoding is the bridge's
        // (ql-dspv2-to-dspv4.cc set_reg_params): stage count n maps to
        // (REG0, REG1) = (n >= 2, n >= 1). Emitting (1,0) would be the trap the
        // plan warns about -- it reads as delay 0, not 1 -- and this form never
        // produces it.
        cell->setParam(ID(AREG0), RTLIL::Const(na >= 2 ? 1 : 0, 1));
        cell->setParam(ID(AREG1), RTLIL::Const(na >= 1 ? 1 : 0, 1));
        cell->setParam(ID(BREG0), RTLIL::Const(nb >= 2 ? 1 : 0, 1));
        cell->setParam(ID(BREG1), RTLIL::Const(nb >= 1 ? 1 : 0, 1));
        // C has a single stage, so it is a plain flag rather than the
        // (n >= 2, n >= 1) pair the two-stage ports use.
        cell->setParam(ID(CREG), RTLIL::Const(nc >= 1 ? 1 : 0, 1));

        // PREG covers both absorbed shapes: the accumulator needs it because
        // CR-5 says a mode feeding P back without it closes a combinational
        // loop through the ALU in dsp4_top, and the pipeline register needs it
        // because it *is* the register. USE_PREG in the techmap then routes P
        // out of the accumulator flops either way.
        cell->setParam(ID(PREG), RTLIL::Const(ff_cell != nullptr ? 1 : 0, 1));

        // Clock enables and resets default to inactive. ARSTN/RSTN/ACCRSTN are
        // active-low, so 1 means "not resetting".
        for (auto id : {ID(CEA), ID(CEB), ID(CEC), ID(CED), ID(CEP)})
            cell->setPort(id, SigSpec(State::S1));
        for (auto id : {ID(ARSTN), ID(RSTN), ID(ACCRSTN)})
            cell->setPort(id, SigSpec(State::S1));

        // A DSP with absorbed operand registers needs a clock even when no
        // output flop was absorbed, and per-port enables for the stages that
        // moved in.
        // A DSP with absorbed operand registers needs a clock even when no
        // output flop was absorbed, and a per-port enable for each stage that
        // moved in. RSTN is shared, so it comes from whichever absorbed chain
        // is present -- they were required to agree above.
        if (na > 0 || nb > 0 || nc > 0) {
            const FlopChain &any = na > 0 ? ca : (nb > 0 ? cb : cc);
            cell->setPort(ID(CLK), any.clk);
            if (na > 0)
                cell->setPort(ID(CEA), resolve(module, ca.en, ca.en_inv));
            if (nb > 0)
                cell->setPort(ID(CEB), resolve(module, cb.en, cb.en_inv));
            if (nc > 0)
                cell->setPort(ID(CEC), resolve(module, cc.en, cc.en_inv));
            if (any.arst != SigSpec(State::S1))
                cell->setPort(ID(RSTN),
                              resolve(module, any.arst, any.arst_inv));
            absorbed_regs += na + nb + nc;
        }

        if (ff_cell != nullptr) {
            cell->setPort(ID(CLK), ff_cell->getPort(ID(CLK)));

            // Clock enable. CEP is active-high (the leaf is `else if (E) Q <= D`),
            // so an active-low $dffe enable has to be inverted rather than
            // wired straight through.
            if (ff_cell->hasPort(ID(EN))) {
                SigSpec en = ff_cell->getPort(ID(EN));
                if (!ff_cell->getParam(ID(EN_POLARITY)).as_bool())
                    en = module->Not(NEW_ID, en);
                cell->setPort(ID(CEP), en);
            }

            // Synchronous reset. The accumulator bank takes .R(ACCRSTN) -- its
            // own pin, separate from the RSTN the operand banks use -- and the
            // leaf is `always @(posedge clk) if (!R) Q <= 0`: synchronous,
            // active-low, resetting to zero. Because ACCRSTN is separate, the
            // output register's reset does not have to match the operand
            // chains'. An $sdff whose reset value is not zero cannot be
            // expressed, so it stays soft rather than resetting to the wrong
            // value.
            if (ff_cell->hasPort(ID(SRST))) {
                if (!ff_cell->getParam(ID(SRST_VALUE)).is_fully_zero()) {
                    left_soft++;
                    log_debug("  %s: left soft -- absorbed flop resets to a "
                              "non-zero value, which the DSP cannot express\n",
                              log_id(st.mul));
                    module->remove(cell);
                    return false;
                }
                SigSpec srst = ff_cell->getPort(ID(SRST));
                // ACCRSTN is active-low; $sdff's polarity says how SRST reads.
                if (ff_cell->getParam(ID(SRST_POLARITY)).as_bool())
                    srst = module->Not(NEW_ID, srst);
                cell->setPort(ID(ACCRSTN), srst);
            }
        }

        if (verbose)
            log("  %s.%s -> %s (%dx%d)\n", log_id(module), log_id(st.mul),
                mode_name, GetSize(ma), GetSize(mb));

        // Absorb the matched cells. pm.autoremove marks them so the matcher
        // does not hand them out again.
        pm.autoremove(st.mul);
        if (st.add)
            pm.autoremove(st.add);
        if (acc_cell)
            pm.autoremove(acc_cell);
        if (ff_cell) {
            pm.autoremove(ff_cell);
            // autoremove is DEFERRED to the matcher's destructor, so this flop
            // is still in the module -- and still in flop_by_q -- while later
            // matches are processed. Without recording it, a subsequent DSP's
            // operand or C chain walks into it, queues it in pending_removal,
            // and it gets removed twice: once by us and once by the destructor.
            // That is a segfault, and C absorption is what made the chains
            // reach far enough back to hit it.
            absorbed.insert(ff_cell);
        }
        // Operand flops are not part of the pmgen match, so autoremove does not
        // know about them. Deleting them here would pull cells out from under a
        // matcher that is still iterating, so they are queued and removed once
        // the run finishes. Recording them also stops a second DSP claiming the
        // same flop before the queue is drained.
        // Queue once per flop. Two chains claiming the same flop is already
        // prevented by the sole-reader guard in collect_flops -- a register
        // feeding both operands has three readers and stops the walk -- but a
        // duplicate here would be a double module->remove(), so check anyway.
        auto claim = [&](RTLIL::Cell *f) {
            if (absorbed.count(f))
                return;
            absorbed.insert(f);
            pending_removal.push_back(f);
        };
        for (int i = 0; i < na; i++)
            claim(ca.flops[i]);
        for (int i = 0; i < nb; i++)
            claim(cb.flops[i]);
        for (int i = 0; i < nc; i++)
            claim(cc.flops[i]);
        return true;
    }

    // ---- Phase 3: operand register absorption (T3.1 / T3.2) -------------
    //
    // A chain of design flops walked back from a multiply operand, plus the
    // control signals every flop in it agreed on.
    struct FlopChain {
        std::vector<RTLIL::Cell *> flops;   // nearest the operand first
        SigSpec source;                     // D of the last flop -- the port value
        SigSpec clk;
        // Enable and async reset are kept as the RAW signal plus its polarity,
        // and only inverted when the cell is wired. Inverting inside the walk
        // created one $not per chain and then compared the two inverters'
        // OUTPUT nets, which are never equal -- so an active-high reset silently
        // absorbed nothing while an active-low one absorbed fine.
        SigSpec en = SigSpec(State::S1), arst = SigSpec(State::S1);
        bool en_inv = false, arst_inv = false;
        // CLK is shared by every leaf, so it is pinned as soon as anything is
        // absorbed -- including by the output flop, which seeds it.
        //
        // The RESET is treated as shared, even though the accumulator has its
        // own ACCRSTN pin and the techmap drives it from there. Underneath,
        // dsp4_top.v clears the P register on `RSTN & ACCRSTN` -- an AND the
        // hardware team places inside the physical mode, below the interface,
        // so a consumer only ever drives ACCRSTN.
        //
        // That is fine as long as one net reaches both pins. It stops being
        // fine if a design gives the accumulator a different reset from the
        // operand registers: the netlist would then say the P register clears
        // on ACCRSTN while the silicon clears it on either. Seeding the reset
        // from the output flop keeps the two nets identical and makes the
        // distinction unobservable.
        //
        // The ENABLE is genuinely per-port: CEA, CEB and CEP are separate and
        // nothing ANDs them, so it is pinned only once a flop joins this chain.
        bool have_clk = false;
        bool have_rst = false;
        bool have_en = false;
    };

    // Resolve a chain's control to a wire, inverting once if the source was the
    // opposite polarity from what the leaf wants.
    static SigSpec resolve(RTLIL::Module *module, const SigSpec &sig, bool invert)
    {
        return invert ? module->Not(NEW_ID, sig) : sig;
    }

    // Two SigSpecs describe the same value.
    static bool same(const SigSpec &a, const SigSpec &b) { return a == b; }

    // Can this flop's controls join a chain that already has these controls?
    // dsp4_logical_map.v gives every internal register one shared CLK, one
    // enable per port (CEA feeds both A stages), and RSTN for the operand banks
    // with ACCRSTN for the accumulator. So the clock must agree with everything
    // absorbed into the cell, while the enable and reset only have to agree
    // with the rest of THIS chain.
    static bool controls_agree(FlopChain &c, const SigSpec &clk,
                               const SigSpec &en, bool en_inv,
                               const SigSpec &arst, bool arst_inv)
    {
        if (c.have_clk && !same(c.clk, clk))
            return false;
        if (c.have_rst && !(same(c.arst, arst) && c.arst_inv == arst_inv))
            return false;
        if (c.have_en && !(same(c.en, en) && c.en_inv == en_inv))
            return false;
        return true;
    }

    // T3.1 -- collect absorbable flops behind `sig`, nearest first.
    //
    // A flop qualifies only if: it drives exactly this value and nothing else
    // (otherwise absorbing would steal a value another cell reads), it is a
    // rising-edge flop, and any async reset is to zero -- the leaf resets to
    // zero and cannot express anything else.
    FlopChain collect_flops(RTLIL::Module *module, SigSpec sig, int max_depth,
                            const SigSpec &clk_seed, const SigSpec &rst_seed,
                            bool rst_seed_inv, bool seeded)
    {
        FlopChain chain;
        chain.source = sig;
        // Seeding pins the clock and the reset from the absorbed output flop --
        // see FlopChain on why the accumulator's reset is not independent. The
        // enable is left free: CEP does not constrain CEA/CEB.
        if (seeded) {
            chain.clk = clk_seed;
            chain.arst = rst_seed;
            chain.arst_inv = rst_seed_inv;
            chain.have_clk = true;
            chain.have_rst = true;
        }
        while (GetSize(chain.flops) < max_depth) {
            auto it = flop_by_q.find(chain.source);
            if (it == flop_by_q.end())
                break;
            RTLIL::Cell *ff = it->second;
            if (absorbed.count(ff))
                break;
            // Sole reader: driven here, read exactly once -- by the cell this
            // absorption is folding it into.
            if (sig_users(ff->getPort(ID::Q)) > 2)
                break;
            if (!ff->getParam(ID(CLK_POLARITY)).as_bool())
                break;
            SigSpec en(State::S1), arst(State::S1);
            bool en_inv = false, arst_inv = false;
            if (ff->hasPort(ID(EN))) {
                en = ff->getPort(ID(EN));
                // CEA/CEB are active-high, so an active-low $dffe enable is the
                // one that needs inverting.
                en_inv = !ff->getParam(ID(EN_POLARITY)).as_bool();
            }
            if (ff->hasPort(ID(SRST))) {
                if (!ff->getParam(ID(SRST_VALUE)).is_fully_zero())
                    break;
                arst = ff->getPort(ID(SRST));
                // RSTN is active-low; an active-high $sdff reset inverts.
                arst_inv = ff->getParam(ID(SRST_POLARITY)).as_bool();
            }
            SigSpec clk = ff->getPort(ID(CLK));
            if (!controls_agree(chain, clk, en, en_inv, arst, arst_inv))
                break;
            chain.clk = clk;
            chain.en = en;
            chain.en_inv = en_inv;
            chain.arst = arst;
            chain.arst_inv = arst_inv;
            chain.have_clk = true;
            chain.have_rst = true;
            chain.have_en = true;
            chain.flops.push_back(ff);
            chain.source = ff->getPort(ID::D);
        }
        return chain;
    }

    // Readers of a signal, from the per-module tally built in index_module().
    // Counted the same way the pmgen `nusers` guards are, so "2" means driven
    // here and read in exactly one place.
    int sig_users(const SigSpec &sig)
    {
        int worst = 0;
        for (auto bit : sigmapper(sig)) {
            auto it = bit_users.find(bit);
            if (it != bit_users.end())
                worst = std::max(worst, it->second);
        }
        return worst;
    }

    // Index a module once: which flop drives which value, and how many cells
    // read each bit. Rebuilding either per candidate made the pass quadratic.
    void index_module(RTLIL::Module *module)
    {
        flop_by_q.clear();
        bit_users.clear();
        absorbed.clear();
        sigmapper.set(module);
        for (auto cell : module->cells()) {
            for (auto &conn : cell->connections())
                for (auto bit : sigmapper(conn.second))
                    bit_users[bit]++;
            // Absorbable flop shapes. The DSP's only fabric-reachable reset is
            // SYNCHRONOUS -- the operating mode drives each leaf R from rstn_i
            // (ACC from accrstn_i) off the routable IC0 bus, and the async pin
            // is chip-global with Fc = 0 and not exposed at all. So an $adff
            // cannot be expressed and stays in fabric.
            //
            // $sdffce is excluded on purpose: there the enable gates the reset,
            // while the DSP flop (and $sdffe) resets regardless of the enable.
            // Absorbing one would hold a register that should have cleared.
            if (cell->type.in(ID($dff), ID($dffe), ID($sdff), ID($sdffe)))
                flop_by_q[cell->getPort(ID::Q)] = cell;
        }
    }

    SigMap sigmapper;
    dict<SigBit, int> bit_users;
    dict<SigSpec, RTLIL::Cell *> flop_by_q;
    pool<RTLIL::Cell *> absorbed;
    std::vector<RTLIL::Cell *> pending_removal;

    bool verbose = false;
    int left_soft = 0;
    int absorbed_regs = 0;

} QlDspV4Pass;

// ============================================================================
// QL_DSP4 configuration checks.
//
// The pre-adder result AD is the two's-complement low 32 bits of D +/- (A|B).
// It wraps on overflow and produces no flag: ffb 4.2.5 removed the saturation
// that used to clamp same-sign additions. On the BMULTSEL path AD is truncated
// again, to 18 bits, feeding the multiplier's I0 port.
//
// Neither shows up as an error. The netlist is structurally valid and the
// arithmetic is right for part of the input range, so a value-comparing
// testbench only catches it if the stimulus happens to reach the corner --
// verify_techmap.py's random vectors do not. Warn at synthesis time rather
// than leaving it to silicon.
//
// Runs immediately before dsp4_logical_map.v, where all four producers
// converge (inference, the Synplify bridge, the macro library, direct
// instantiation), so one check covers every route to the cell.
// ============================================================================

// Bits needed to hold the signed value: the width left after stripping a
// redundant sign-extension run off the top. An 18-bit value sign-extended to 32
// returns 18, so extension does not read as risk.
static int signed_width(const SigSpec &sig)
{
    int n = GetSize(sig);
    if (n <= 1)
        return n;
    int i = n - 2;
    while (i >= 0 && sig[i] == sig[n - 1])
        i--;
    return i + 2;
}

struct QlDsp4CheckPass : public Pass {
    QlDsp4CheckPass()
        : Pass("ql_dsp4_check", "warn about QL_DSP4 arithmetic that can silently overflow")
    {
    }

    void help() override
    {
        log("\n");
        log("    ql_dsp4_check [selection]\n");
        log("\n");
        log("Warn about QL_DSP4 pre-adder configurations whose result can overflow\n");
        log("silently. The DSP-V4 pre-adder wraps in two's complement and emits no\n");
        log("overflow flag, so whether a design is correct depends on its data range.\n");
        log("\n");
        log("    -max-report N\n");
        log("        detail at most N cells, then summarise (default 10).\n");
        log("\n");
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        log_header(design, "Executing QL_DSP4_CHECK pass.\n");

        int max_report = 10;
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-max-report" && argidx + 1 < args.size()) {
                max_report = atoi(args[++argidx].c_str());
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        int at_risk = 0, reported = 0, preadd_cells = 0;
        int ce_over = 0, ce_reported = 0;

        // The tile feeds all five CE ports from a 3-input crossbar
        // (vpr.xml: `complete` on dsp.IC0[0..2] -> cea/ceb/cec/ced/cep), so a
        // cell may use at most THREE distinct clock-enable signals. ffb 4.2.5
        // records this as a DRC because the mux sits outside the DSP RTL and so
        // is invisible to the cell's own definition.
        //
        // Only a port whose register is actually enabled consumes a slot: with
        // CREG = 0 the techmap never instantiates the C flops, so CEC drives
        // nothing. Constants do not count either.
        struct CeUse { RTLIL::IdString reg_a, reg_b, ce; int width; const char *name; };
        static const CeUse CE_USES[] = {
            // Widest first -- if the limit is exceeded, the widest ports are the
            // ones worth keeping, so they are reported as the survivors.
            {ID(CREG),  RTLIL::IdString(), ID(CEC), 50, "C"},
            {ID(PREG),  ID(MREG),          ID(CEP), 50, "P"},
            {ID(AREG0), ID(AREG1),         ID(CEA), 32, "A"},
            {ID(DREG),  RTLIL::IdString(), ID(CED), 27, "D"},
            {ID(BREG0), ID(BREG1),         ID(CEB), 18, "B"},
        };

        for (auto module : design->selected_modules()) {
            SigMap sigmap(module);
            for (auto cell : module->selected_cells()) {
                if (cell->type != ID(QL_DSP4))
                    continue;
                bool amultsel = cell->getParam(ID(AMULTSEL)).as_bool();
                bool bmultsel = cell->getParam(ID(BMULTSEL)).as_bool();
                if (!amultsel && !bmultsel)
                    continue;
                preadd_cells++;

                RTLIL::Const inmode = cell->getParam(ID(INMODE));
                bool preaddinsel = cell->getParam(ID(PREADDINSEL)).as_bool();
                bool d_active = inmode.extract(2, 1).as_bool();
                bool gated = inmode.extract(1, 1).as_bool();

                // Mirror dsp4_logical_map.v: I1 is the sign-extended B path
                // under PREADDINSEL, else the A path; INMODE[1] zero-gates
                // whichever one PREADDINSEL selected; I0 is D unless INMODE[2]
                // gates it off. A gated operand is a constant zero and cannot
                // push the sum over.
                int w_i0 = d_active ? signed_width(sigmap(cell->getPort(ID(D)))) : 1;
                int w_i1 = 1;
                if (!gated)
                    w_i1 = signed_width(
                        sigmap(cell->getPort(preaddinsel ? ID(B) : ID(A))));

                // D +/- I1 needs one bit more than the wider operand.
                int w_sum = std::max(w_i0, w_i1) + 1;
                const char *op = inmode.extract(3, 1).as_bool() ? "D - " : "D + ";
                const char *rhs = preaddinsel ? "B" : "A";

                // AMULTSEL keeps all 32 bits of AD; BMULTSEL truncates to
                // AD[17:0] for the 18-bit multiplier port, a much lower ceiling.
                int keep = bmultsel ? 18 : 32;
                if (w_sum <= keep)
                    continue;

                at_risk++;
                if (reported >= max_report)
                    continue;
                reported++;
                if (bmultsel)
                    log_warning(
                        "%s.%s: DSP-V4 pre-adder %s%s needs %d bits, but BMULTSEL "
                        "feeds the result to the 18-bit multiplier port as AD[17:0]. "
                        "The high bits are discarded silently -- results are correct "
                        "only while |%s%s| < 2^17. Narrow an operand, or pre-add in "
                        "fabric.\n",
                        log_id(module), log_id(cell), op, rhs, w_sum, op, rhs);
                else
                    log_warning(
                        "%s.%s: DSP-V4 pre-adder %s%s needs %d bits and AD holds 32. "
                        "The pre-adder wraps in two's complement and raises no overflow "
                        "flag, so results are correct only while the sum stays in the "
                        "32-bit signed range. Narrow an operand to 31 bits, or pre-add "
                        "in fabric.\n",
                        log_id(module), log_id(cell), op, rhs, w_sum);
            }

            // Clock-enable crossbar DRC.
            for (auto cell : module->selected_cells()) {
                if (cell->type != ID(QL_DSP4))
                    continue;
                std::vector<std::pair<SigSpec, const char *>> used;
                std::string kept, dropped;
                for (auto &u : CE_USES) {
                    bool on = cell->hasParam(u.reg_a) &&
                              cell->getParam(u.reg_a).as_bool();
                    if (!on && u.reg_b != RTLIL::IdString())
                        on = cell->hasParam(u.reg_b) &&
                             cell->getParam(u.reg_b).as_bool();
                    if (!on || !cell->hasPort(u.ce))
                        continue;
                    SigSpec ce = sigmap(cell->getPort(u.ce));
                    if (ce.is_fully_const())
                        continue;   // a tied enable needs no routed signal
                    bool seen = false;
                    for (auto &p : used)
                        if (p.first == ce) { seen = true; break; }
                    if (!seen)
                        used.push_back({ce, u.name});
                    std::string &tgt = (GetSize(used) <= 3) ? kept : dropped;
                    if (!tgt.empty())
                        tgt += " ";
                    tgt += u.name;
                }
                if (GetSize(used) <= 3)
                    continue;
                ce_over++;
                if (ce_reported >= max_report)
                    continue;
                ce_reported++;
                log_warning(
                    "%s.%s: %d distinct clock enables on the DSP's registered "
                    "ports, but the tile crossbar feeds all five CE pins from "
                    "only 3 signals. Keep the widest (%s) inside the DSP and "
                    "move %s back to fabric, or drive the extra ports from an "
                    "enable already in use.\n",
                    log_id(module), log_id(cell), GetSize(used),
                    kept.c_str(), dropped.c_str());
            }
        }

        if (at_risk > reported)
            log_warning("%d further QL_DSP4 pre-adder cell(s) carry the same overflow "
                        "risk; re-run with -max-report to list them.\n",
                        at_risk - reported);
        if (ce_over > ce_reported)
            log_warning("%d further QL_DSP4 cell(s) exceed the 3-signal clock-enable "
                        "limit.\n", ce_over - ce_reported);
        if (preadd_cells)
            log("ql_dsp4_check: %d QL_DSP4 pre-adder cell(s), %d at risk of silent "
                "overflow.\n",
                preadd_cells, at_risk);
        if (ce_over)
            log("ql_dsp4_check: %d QL_DSP4 cell(s) over the 3-signal clock-enable "
                "limit.\n", ce_over);
    }

} QlDsp4CheckPass;

PRIVATE_NAMESPACE_END
