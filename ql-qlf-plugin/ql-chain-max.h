// Parser for the -chain_max value, shared by synth_ql and ql_dspv4.
#include <limits.h>
#include <string>

// Accepts digits only: no sign, no space, no trailing text, no empty value.
static inline int parse_chain_max(const std::string &value)
{
    long long number = 0;
    bool valid = !value.empty();
    for (char character : value) {
        if (character < '0' || character > '9') {
            valid = false;
            break;
        }
        number = number * 10 + (character - '0');
        if (number > INT_MAX) {
            valid = false;
            break;
        }
    }
    if (!valid)
        Yosys::log_cmd_error("-chain_max expects a non-negative integer, got '%s'.\n", value.c_str());
    return (int)number;
}
