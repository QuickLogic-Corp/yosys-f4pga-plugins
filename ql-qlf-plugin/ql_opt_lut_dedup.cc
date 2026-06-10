#include "kernel/yosys.h"
#include "kernel/sigtools.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct OptLutDedupPass : public Pass {
    OptLutDedupPass() : Pass("opt_lut_dedup", 
        "remove duplicate inputs from $lut cells") {}

    void execute(std::vector<std::string> args, 
                 RTLIL::Design *design) override
    {
        log_header(design, "Executing OPT_LUT_DEDUP pass.\n");

        for (auto module : design->selected_modules())
        {
            SigMap sigmap(module);
            bool any_changed = true;

            while (any_changed)
            {
                any_changed = false;

                for (auto cell : module->selected_cells())
                {
                    if (cell->type != ID($lut)) continue;

                    int width   = cell->getParam(ID(WIDTH)).as_int();
                    SigSpec A   = cell->getPort(ID(A));
                    Const lut   = cell->getParam(ID(LUT));

                    // Find first duplicate pair
                    int dup_keep = -1, dup_remove = -1;
                    for (int i = 0; i < width && dup_keep < 0; i++)
                        for (int j = i+1; j < width && dup_keep < 0; j++)
                            if (sigmap(A[i]) == sigmap(A[j])) {
                                dup_keep   = i;
                                dup_remove = j;
                            }

                    if (dup_keep < 0) continue; // no duplicate found

                    log("  %s.%s: removing duplicate input %d (== input %d), "
                        "LUT%d -> LUT%d\n",
                        log_id(module), log_id(cell),
                        dup_remove, dup_keep, width, width-1);

                    // Compute new INIT
                    int new_width = width - 1;
                    int new_size  = 1 << new_width;
                    Const new_lut(State::S0, new_size);

                    for (int new_idx = 0; new_idx < new_size; new_idx++)
                    {
                        int old_idx = 0;
                        for (int bit = 0; bit < width; bit++)
                        {
                            int val;
                            if (bit < dup_remove)
                                val = (new_idx >> bit) & 1;
                            else if (bit == dup_remove)
                                val = (new_idx >> dup_keep) & 1; // mirror kept input
                            else
                                val = (new_idx >> (bit - 1)) & 1;

                            old_idx |= val << bit;
                        }
                        new_lut.bits()[new_idx] = lut.bits()[old_idx];
                    }

                    // Build new A without the removed input
                    SigSpec new_A;
                    for (int k = 0; k < width; k++)
                        if (k != dup_remove) new_A.append(A[k]);

                    cell->setParam(ID(WIDTH), new_width);
                    cell->setParam(ID(LUT),   new_lut);
                    cell->setPort(ID(A),       new_A);

                    any_changed = true; // re-scan for more duplicates
                }
            }
        }
    }
} OptLutDedupPass;

PRIVATE_NAMESPACE_END