// dspv4_modes.inc -- GENERATED FILE, DO NOT EDIT BY HAND.
//
// Regenerate:  aurora2/scripts/dspv4/gen_mode_table.py
// Check:       aurora2/scripts/dspv4/gen_mode_table.py --check
// Source:      aurora2 docs/development/DSPV2-to-DSPV4-Synthesis/dspv4_modes.yaml
//
// The DSP-V4 control words, for the inference pass to look up once it has
// classified a matched shape. The YAML is the single source (CR-3): the same
// file drives the verification harness, so a mode this table can emit is a mode
// the harness checks.
//
// `supplemental` marks a mode that is not in the hardware spreadsheet -- see
// SUPPLEMENTAL_MODES in extract_dspv4_modes.py for why each exists.

struct Dspv4Mode {
    const char *name;
    uint16_t opmode;
    uint8_t alumode, inmode, carryinsel, use_simd;
    uint8_t amultsel, bmultsel, preaddinsel;
    bool supplemental;
};


static const Dspv4Mode DSPV4_MODES[] = {
    {"MULT",                 5, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ADD_C",           53, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_SUB_C",           53, 3, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ACC",             37, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ACC_C",           421, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ADD",             21, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ADD_C_CASC",      405, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ADD_PCIN17",      85, 0, 0, 0, 0, 0, 0, 0, false},
    {"MULT_ADD_P17",         101, 0, 0, 0, 0, 0, 0, 0, false},
    {"PREADD_A_MULT_B",      5, 0, 4, 0, 0, 1, 0, 0, false},
    {"PREADD_A_SUB_B",       5, 0, 12, 0, 0, 1, 0, 0, false},
    {"PREADD_A_MULT_B_C",    53, 0, 4, 0, 0, 1, 0, 0, false},
    {"PREADD_A_MACC",        37, 0, 4, 0, 0, 1, 0, 0, false},
    {"PREADD_A_MACC_C",      421, 0, 4, 0, 0, 1, 0, 0, false},
    {"PREADD_A_MULT_B_CASC", 21, 0, 4, 0, 0, 1, 0, 0, false},
    {"D_MULT_B",             5, 0, 6, 0, 0, 1, 0, 0, false},
    {"D_MULT_B_C",           53, 0, 6, 0, 0, 1, 0, 0, false},
    {"NEG_A_MULT_B",         5, 0, 8, 0, 0, 1, 0, 0, false},
    {"PREADD_B_MULT_A",      5, 0, 4, 0, 0, 0, 1, 1, false},
    {"PREADD_B_SUB_A",       5, 0, 12, 0, 0, 0, 1, 1, false},
    {"PREADD_B_MULT_A_C",    53, 0, 4, 0, 0, 0, 1, 1, false},
    {"PREADD_B_MACC",        37, 0, 4, 0, 0, 0, 1, 1, false},
    {"PREADD_B_MACC_C",      421, 0, 4, 0, 0, 0, 1, 1, false},
    {"D_MULT_A",             5, 0, 6, 0, 0, 0, 1, 1, false},
    {"D_MULT_A_C",           53, 0, 6, 0, 0, 0, 1, 1, false},
    {"NEG_B_MULT_A",         5, 0, 8, 0, 0, 0, 1, 1, false},
    {"SQ_A",                 5, 0, 4, 0, 0, 1, 1, 0, false},
    {"SQ_A_SUB",             5, 0, 12, 0, 0, 1, 1, 0, false},
    {"SQ_A_C",               53, 0, 4, 0, 0, 1, 1, 0, false},
    {"SQ_A_ACC",             37, 0, 4, 0, 0, 1, 1, 0, false},
    {"SQ_D_A",               5, 0, 6, 0, 0, 1, 1, 0, false},
    {"SQ_A_ONLY",            5, 0, 0, 0, 0, 1, 1, 0, false},
    {"SQ_A_NEG",             5, 3, 0, 0, 0, 1, 1, 0, false},
    {"SQ_B",                 5, 0, 4, 0, 0, 1, 1, 1, false},
    {"SQ_B_SUB",             5, 0, 12, 0, 0, 1, 1, 1, false},
    {"SQ_B_ONLY",            5, 0, 0, 0, 0, 1, 1, 1, false},
    {"SQ_B_NEG",             5, 3, 0, 0, 0, 1, 1, 1, false},
    {"XPATH_A",              5, 0, 4, 0, 0, 0, 1, 0, false},
    {"XPATH_B",              5, 0, 4, 0, 0, 1, 0, 1, false},
    {"ADD_AB_C",             51, 0, 0, 0, 0, 0, 0, 0, false},
    {"SUB_C_AB",             51, 3, 0, 0, 0, 0, 0, 0, false},
    {"RSUB_AB_C",            51, 1, 0, 0, 0, 0, 0, 0, false},
    {"ACC_AB",               35, 0, 0, 0, 0, 0, 0, 0, false},
    {"SUB_P_AB",             35, 3, 0, 0, 0, 0, 0, 0, false},
    {"ADD_AB_PCIN",          19, 0, 0, 0, 0, 0, 0, 0, false},
    {"SUB_PCIN_AB",          19, 3, 0, 0, 0, 0, 0, 0, false},
    {"ADD_AB_C_P",           419, 0, 0, 0, 0, 0, 0, 0, false},
    {"ADD_AB_C_PCIN",        403, 0, 0, 0, 0, 0, 0, 0, false},
    {"ADD_C_P",              416, 0, 0, 0, 0, 0, 0, 0, false},
    {"ADD_C_PCIN",           400, 0, 0, 0, 0, 0, 0, 0, false},
    {"ACC_PCIN",             144, 0, 0, 0, 0, 0, 0, 0, false},
    {"ADD_AB_PCIN17",        83, 0, 0, 0, 0, 0, 0, 0, false},
    {"ADD_AB_P17",           99, 0, 0, 0, 0, 0, 0, 0, false},
    {"ACC_PCIN17",           208, 0, 0, 0, 0, 0, 0, 0, false},
    {"SIMD2_ADD_C",          51, 0, 0, 0, 1, 0, 0, 0, false},
    {"SIMD2_ACC",            35, 0, 0, 0, 1, 0, 0, 0, false},
    {"SIMD2_ADD_PCIN",       19, 0, 0, 0, 1, 0, 0, 0, false},
    {"SIMD4_ADD_C",          51, 0, 0, 0, 2, 0, 0, 0, false},
    {"SIMD4_ACC",            35, 0, 0, 0, 2, 0, 0, 0, false},
    {"SIMD4_ADD_PCIN",       19, 0, 0, 0, 2, 0, 0, 0, false},
    {"PASS_AB",              3, 0, 0, 0, 0, 0, 0, 0, false},
    {"PASS_C",               48, 0, 0, 0, 0, 0, 0, 0, false},
    {"PASS_P",               32, 0, 0, 0, 0, 0, 0, 0, false},
    {"PASS_PCIN",            16, 0, 0, 0, 0, 0, 0, 0, false},
    {"LOAD_AB_P",            3, 0, 0, 0, 0, 0, 0, 0, false},
    {"WIDE_ADD_LO",          51, 0, 0, 0, 0, 0, 0, 0, false},
    {"WIDE_ADD_HI",          51, 0, 0, 2, 0, 0, 0, 0, false},
    {"WIDE_ACC_LO",          35, 0, 0, 0, 0, 0, 0, 0, false},
    {"WIDE_ACC_HI",          35, 0, 0, 2, 0, 0, 0, 0, false},
    {"MACC100_LO",           51, 0, 0, 0, 0, 0, 0, 0, false},
    {"MACC100_HI",           53, 0, 0, 2, 0, 0, 0, 0, false},
    {"MACC100S_LO",          51, 0, 0, 0, 0, 0, 0, 0, false},
    {"MACC100S_HI",          453, 0, 0, 0, 0, 0, 0, 0, false},
    {"NOT_SUM_AB_C",         51, 2, 0, 0, 0, 0, 0, 0, true},
};

static const size_t DSPV4_MODE_COUNT = sizeof(DSPV4_MODES) / sizeof(DSPV4_MODES[0]);
