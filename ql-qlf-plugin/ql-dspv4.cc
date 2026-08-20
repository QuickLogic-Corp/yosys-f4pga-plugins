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
            ql_dspv4_pm pm(module, module->selected_cells());
            pm.run_ql_dspv4([&]() {
                if (emit(pm, module))
                    total++;
            });
        }
        log("ql_dspv4: inferred %d QL_DSP4 cell(s), %d multiply idiom(s) left "
            "soft.\n", total, left_soft);
    }

    // Map a matched shape to a mode name, or nullptr if this shape has no
    // multiply-form control word and must stay soft.
    const char *classify(ql_dspv4_pm &pm, std::string &why)
    {
        auto &st = pm.st_ql_dspv4;
        if (st.add == nullptr)
            return "MULT";
        if (st.ff != nullptr) {
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
        const char *mode_name = classify(pm, why);
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

        cell->setPort(ID::A, dspv4_fit(module, ma, DSPV4_A_WIDTH, a_signed));
        cell->setPort(ID::B, dspv4_fit(module, mb, DSPV4_B_WIDTH, b_signed));

        bool acc = st.ff != nullptr;
        SigSpec result = acc ? st.ff->getPort(ID::Q)
                        : st.add ? st.add->getPort(ID::Y)
                                 : st.mul->getPort(ID::Y);

        // C is the adder operand that is not the product. Present for
        // MULT_ADD_C / MULT_SUB_C, and for MULT_ACC_C where the first adder
        // takes C and the second takes the accumulator feedback. Plain MULT_ACC
        // has one adder whose other operand IS the feedback, so no C.
        // Where C comes from depends on the shape:
        //   MULT_ADD_C / MULT_SUB_C : `add`'s non-product operand
        //   MULT_ACC_C              : `acc`'s non-chain operand -- `add` holds
        //                             the accumulator feedback, not C
        //   MULT_ACC                : no C at all
        RTLIL::Cell *c_cell = st.acc != nullptr ? st.acc
                            : (st.add != nullptr && !acc) ? st.add : nullptr;
        IdString c_port = st.acc != nullptr ? st.acc_ba : st.add_ba;
        if (c_cell != nullptr) {
            SigSpec c = c_cell->getPort(c_port);
            bool c_signed = c_cell->getParam(
                c_port == ID::A ? ID::A_SIGNED : ID::B_SIGNED).as_bool();
            cell->setPort(ID(C), dspv4_fit(module, c, DSPV4_C_WIDTH, c_signed));
        }

        cell->setPort(ID(P), dspv4_wide_out(module, result, DSPV4_P_WIDTH));

        // CR-5: any mode that feeds P back needs the P register, or dsp4_top
        // closes a combinational loop through the ALU.
        cell->setParam(ID(PREG), RTLIL::Const(acc ? 1 : 0, 1));

        // Clock enables and resets default to inactive. ARSTN/RSTN/ACCRSTN are
        // active-low, so 1 means "not resetting".
        for (auto id : {ID(CEA), ID(CEB), ID(CEC), ID(CED), ID(CEP)})
            cell->setPort(id, SigSpec(State::S1));
        for (auto id : {ID(ARSTN), ID(RSTN), ID(ACCRSTN)})
            cell->setPort(id, SigSpec(State::S1));

        if (acc) {
            cell->setPort(ID(CLK), st.ff->getPort(ID(CLK)));

            // Clock enable. CEP is active-high (the leaf is `else if (E) Q <= D`),
            // so an active-low $dffe enable has to be inverted rather than
            // wired straight through.
            if (st.ff->hasPort(ID(EN))) {
                SigSpec en = st.ff->getPort(ID(EN));
                if (!st.ff->getParam(ID(EN_POLARITY)).as_bool())
                    en = module->Not(NEW_ID, en);
                cell->setPort(ID(CEP), en);
            }

            // Asynchronous reset. The accumulator flops take .R(ARSTN), and the
            // leaf is `always @(posedge clk or negedge R) if (!R) Q <= 0` --
            // asynchronous, active-low, resetting to zero. An $adff whose reset
            // value is not zero cannot be expressed, so it stays soft rather
            // than silently resetting to the wrong value.
            if (st.ff->hasPort(ID(ARST))) {
                if (!st.ff->getParam(ID(ARST_VALUE)).is_fully_zero()) {
                    left_soft++;
                    log_debug("  %s: left soft -- accumulator reset value is "
                              "not zero, which the DSP cannot express\n",
                              log_id(st.mul));
                    module->remove(cell);
                    return false;
                }
                SigSpec arst = st.ff->getPort(ID(ARST));
                // ARSTN is active-low; $adff's polarity says how ARST reads.
                if (st.ff->getParam(ID(ARST_POLARITY)).as_bool())
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
        if (st.acc)
            pm.autoremove(st.acc);
        if (st.ff)
            pm.autoremove(st.ff);
        return true;
    }

    bool verbose = false;
    int left_soft = 0;

} QlDspV4Pass;

PRIVATE_NAMESPACE_END
