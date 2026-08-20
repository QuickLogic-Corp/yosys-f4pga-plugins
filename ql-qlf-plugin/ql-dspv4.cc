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
// hardware limit, not a policy choice: AREG0 drives QL_DSP4_A1_DFFRE and AREG1
// drives A2_DFFRE, and there is no third stage.
static const int DSPV4_MAX_OPERAND_STAGES = 2;

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

        // T3.1 / T3.2 -- absorb the designer's operand registers.
        //
        // Latency balancing is the whole difficulty. Absorbing n stages on A
        // replaces n external flops with n internal ones, so a path's total
        // delay is unchanged -- but only if the flops really are there. The plan
        // therefore absorbs the largest COMMON depth and leaves the surplus
        // external: with A two deep and B one deep, one stage moves in on each
        // and A keeps one flop outside.
        //
        // C is deliberately left alone. Its path does not change when A and B
        // move their own registers inward, so the product still meets C on the
        // cycle the RTL said it would; adding CREG would shift it.
        //
        // Any absorbed flop must already agree with the flop absorbed on the
        // output, if there was one, because the leaves share CLK and ARSTN.
        int na = 0, nb = 0;
        FlopChain ca, cb;
        {
            bool seeded = ff_cell != nullptr;
            SigSpec seed_clk, seed_arst(State::S1);
            if (seeded) {
                seed_clk = ff_cell->getPort(ID(CLK));
                if (ff_cell->hasPort(ID(ARST))) {
                    seed_arst = ff_cell->getPort(ID(ARST));
                    if (ff_cell->getParam(ID(ARST_POLARITY)).as_bool())
                        seed_arst = module->Not(NEW_ID, seed_arst);
                }
            }
            ca = collect_flops(module, ma, DSPV4_MAX_OPERAND_STAGES, seed_clk,
                               seed_arst, seeded);
            cb = collect_flops(module, mb, DSPV4_MAX_OPERAND_STAGES, seed_clk,
                               seed_arst, seeded);
            int common = std::min(GetSize(ca.flops), GetSize(cb.flops));
            // Both ports must end up on the same CLK and ARSTN.
            if (common > 0 && !(same(ca.clk, cb.clk) && same(ca.arst, cb.arst)))
                common = 0;
            na = nb = common;
        }
        if (na > 0) {
            ma = ca.flops[na - 1]->getPort(ID::D);
            mb = cb.flops[nb - 1]->getPort(ID::D);
        }

        cell->setPort(ID::A, dspv4_fit(module, ma, DSPV4_A_WIDTH, a_signed));
        cell->setPort(ID::B, dspv4_fit(module, mb, DSPV4_B_WIDTH, b_signed));

        // With a flop absorbed the DSP drives its Q directly; the
        // combinational result never appears in the netlist at all.
        bool acc = feedback;
        SigSpec result = ff_cell != nullptr ? ff_cell->getPort(ID::Q)
                                            : dsp_result;

        // C is the adder operand that is not the product. Present for
        // MULT_ADD_C / MULT_SUB_C, and for MULT_ACC_C where the first adder
        // takes C and the second takes the accumulator feedback. Plain MULT_ACC
        // has one adder whose other operand IS the feedback, so no C.
        // Where C comes from depends on the shape:
        //   MULT_ADD_C / MULT_SUB_C : `add`'s non-product operand
        //   MULT_ACC_C              : `acc`'s non-chain operand -- `add` holds
        //                             the accumulator feedback, not C
        //   MULT_ACC                : no C at all
        RTLIL::Cell *c_cell = acc_cell != nullptr ? acc_cell
                            : (st.add != nullptr && !acc) ? st.add : nullptr;
        IdString c_port = acc_cell != nullptr ? st.acc_ba : st.add_ba;
        if (c_cell != nullptr) {
            SigSpec c = c_cell->getPort(c_port);
            bool c_signed = c_cell->getParam(
                c_port == ID::A ? ID::A_SIGNED : ID::B_SIGNED).as_bool();
            // A C operand wider than the port would be truncated by
            // dspv4_fit, which is a wrong answer rather than a missed
            // optimisation. Refuse the shape instead; the matcher then offers
            // the bare multiply, so the product still lands in a DSP and only
            // the addition stays soft.
            if (GetSize(c) > DSPV4_C_WIDTH) {
                left_soft++;
                log_debug("  %s: left soft -- %d-bit C operand exceeds the "
                          "%d-bit C port\n",
                          log_id(st.mul), GetSize(c), DSPV4_C_WIDTH);
                module->remove(cell);
                return false;
            }
            cell->setPort(ID(C), dspv4_fit(module, c, DSPV4_C_WIDTH, c_signed));
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
        if (na > 0) {
            cell->setPort(ID(CLK), ca.clk);
            cell->setPort(ID(CEA), ca.en);
            cell->setPort(ID(CEB), cb.en);
            if (ca.arst != SigSpec(State::S1))
                cell->setPort(ID(ARSTN), ca.arst);
            absorbed_regs += na + nb;
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

            // Asynchronous reset. The accumulator flops take .R(ARSTN), and the
            // leaf is `always @(posedge clk or negedge R) if (!R) Q <= 0` --
            // asynchronous, active-low, resetting to zero. An $adff whose reset
            // value is not zero cannot be expressed, so it stays soft rather
            // than silently resetting to the wrong value.
            if (ff_cell->hasPort(ID(ARST))) {
                if (!ff_cell->getParam(ID(ARST_VALUE)).is_fully_zero()) {
                    left_soft++;
                    log_debug("  %s: left soft -- absorbed flop resets to a "
                              "non-zero value, which the DSP cannot express\n",
                              log_id(st.mul));
                    module->remove(cell);
                    return false;
                }
                SigSpec arst = ff_cell->getPort(ID(ARST));
                // ARSTN is active-low; $adff's polarity says how ARST reads.
                if (ff_cell->getParam(ID(ARST_POLARITY)).as_bool())
                    arst = module->Not(NEW_ID, arst);
                cell->setPort(ID(ARSTN), arst);
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
        if (ff_cell)
            pm.autoremove(ff_cell);
        // Operand flops are not part of the pmgen match, so autoremove does not
        // know about them. Deleting them here would pull cells out from under a
        // matcher that is still iterating, so they are queued and removed once
        // the run finishes. Recording them also stops a second DSP claiming the
        // same flop before the queue is drained.
        for (int i = 0; i < na; i++) {
            absorbed.insert(ca.flops[i]);
            pending_removal.push_back(ca.flops[i]);
        }
        for (int i = 0; i < nb; i++) {
            absorbed.insert(cb.flops[i]);
            pending_removal.push_back(cb.flops[i]);
        }
        return true;
    }

    // ---- Phase 3: operand register absorption (T3.1 / T3.2) -------------
    //
    // A chain of design flops walked back from a multiply operand, plus the
    // control signals every flop in it agreed on.
    struct FlopChain {
        std::vector<RTLIL::Cell *> flops;   // nearest the operand first
        SigSpec source;                     // D of the last flop -- the port value
        SigSpec clk, en, arst;              // en/arst are S1 when absent
        bool have_clk = false;
    };

    // Two SigSpecs describe the same value.
    static bool same(const SigSpec &a, const SigSpec &b) { return a == b; }

    // Can this flop's controls join a chain that already has these controls?
    // dsp4_logical_map.v gives every internal register ONE shared ARSTN and ONE
    // shared CLK, and one enable per port (CEA feeds both A stages), so a chain
    // is only absorbable if its members already agree.
    static bool controls_agree(FlopChain &c, const SigSpec &clk,
                               const SigSpec &en, const SigSpec &arst)
    {
        if (!c.have_clk)
            return true;
        return same(c.clk, clk) && same(c.en, en) && same(c.arst, arst);
    }

    // T3.1 -- collect absorbable flops behind `sig`, nearest first.
    //
    // A flop qualifies only if: it drives exactly this value and nothing else
    // (otherwise absorbing would steal a value another cell reads), it is a
    // rising-edge flop, and any async reset is to zero -- the leaf resets to
    // zero and cannot express anything else.
    FlopChain collect_flops(RTLIL::Module *module, SigSpec sig, int max_depth,
                            const SigSpec &clk_seed, const SigSpec &arst_seed,
                            bool seeded)
    {
        FlopChain chain;
        chain.source = sig;
        if (seeded) {
            chain.clk = clk_seed;
            chain.arst = arst_seed;
            chain.en = SigSpec(State::S1);
            chain.have_clk = true;
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
            if (ff->hasPort(ID(EN))) {
                en = ff->getPort(ID(EN));
                if (!ff->getParam(ID(EN_POLARITY)).as_bool())
                    en = module->Not(NEW_ID, en);
            }
            if (ff->hasPort(ID(ARST))) {
                if (!ff->getParam(ID(ARST_VALUE)).is_fully_zero())
                    break;
                arst = ff->getPort(ID(ARST));
                if (ff->getParam(ID(ARST_POLARITY)).as_bool())
                    arst = module->Not(NEW_ID, arst);
            }
            SigSpec clk = ff->getPort(ID(CLK));
            if (!controls_agree(chain, clk, en, arst))
                break;
            chain.clk = clk;
            chain.en = en;
            chain.arst = arst;
            chain.have_clk = true;
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
            if (cell->type.in(ID($dff), ID($adff), ID($dffe), ID($adffe)))
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

PRIVATE_NAMESPACE_END
