/*
 *  yosys -- Yosys Open SYnthesis Suite
 *
 *  Copyright (C) 2023  Martin Povišer <povik@cutebit.org>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include "kernel/register.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

#define QL_HEXFILE_BITSTRIDE 36

std::string hexdump(std::vector<State>::iterator start, std::vector<State>::iterator end)
{
    std::string ret;
    ret.reserve(9);
    for (auto p = start; p != end;) {
        auto ne = p + 4;
        int nibble = 0;
        for (int i = 0; p != end && p != ne; p++, i++)
            if (*p == State::S1)
                nibble |= 1 << i;
        ret += (nibble < 10 ? '0' + nibble : 'A' - 10 + nibble);
    }
    return ret;
}

void write_hex(const char *name, std::ostream &s, Const data)
{
    log_assert(data.size() % QL_HEXFILE_BITSTRIDE == 0);
    for (auto p = data.bits.begin(); p != data.bits.end(); p += QL_HEXFILE_BITSTRIDE)
        s << hexdump(p, p + 36) << "\n";

    if (s.fail())
        log_error("Failed to write to %s\n", name);
}

void read_hex(const char *name, std::istream &s, Const &data)
{
    log_assert(data.size() % QL_HEXFILE_BITSTRIDE == 0);
    char line[16];
    int lineno = 0;
    int p = 0;
    while (!s.getline(line, sizeof(line)).fail() &&
            lineno < data.size() / QL_HEXFILE_BITSTRIDE) {
        lineno++;
        int i;
        for (i = 0; i < 9; i++) {
            int nibble;
            switch (line[i]) {
            case '0' ... '9':
                nibble = line[i] - '0';
                break;
            case 'A' ... 'F':
                nibble = line[i] - 'A' + 10;
                break;
            default:
                goto bad_data;
            }

            for (int k = 0; k < 4; k++)
                data[(lineno - 1) * 36 + i * 4 + k] = nibble & 1 << k ? State::S1 : State::S0;
        }

        if (!line[i])
            continue;

    bad_data:
        log_error("Bad data on line %d of %s: %s", lineno, name, line);
    }

    if (s.eof())
        return;

    if (s.fail())
        log_error("Failed to read %s\n", name);

    lineno++;
    log_error("Overrun data on line %d in %s\n", lineno, name);
}

struct QlBramInitfilePass : Pass {
    QlBramInitfilePass() : Pass("ql_bram_initfile", "read or write RAM init files in QuickLogic flows") {}

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    ql_bram_initfile {-read|-write} [-path <dir-path>] [selection]\n");
        log("\n");
        log("This pass reads/writes initialization data on QuickLogic BRAM primitives from/to\n");
        log("an external file. The filename is stored in the RAM_INIT_FILE parameter, the\n");
        log("value of which will be generated if not set.\n");
        log("\n");
        log("    -read -write\n");
        log("        select a read or write mode\n");
        log("\n");
        log("    -path <dir-path>\n");
        log("        set the base directory path relative to which the RAM_INIT_FILE filenames\n");
        log("        are interpreted\n");
        log("\n");
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        log_header(design, "Executing QL_BRAM_INITFILE pass. (read or write RAM init files in QuickLogic flows)\n");
        std::string dir_path;
        bool read = false, write = false;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-read")
                read = true;
            else if (args[argidx] == "-write")
                write = true;
            else if (args[argidx] == "-path" && argidx + 1 < args.size())
                dir_path = args[++argidx];
            else
                break;
        }
        extra_args(args, argidx, design);

        if ((!read && !write) || (read && write))
            log_error("One of read or write modes needs to be selected.\n");

        pool<std::string> used_filenames;

        for (auto module : design->selected_modules()) {
            for (auto cell : module->selected_cells()) {
                if (!cell->type.in(ID(TDP36K)))
                    continue;

                if (!cell->hasParam(ID(RAM_INIT))) {
                    log_warning("%s cell %s lacks RAM_DATA parameter, cell skipped.\n",
                                log_id(cell->type), log_id(cell));
                    continue;
                }

                if (write && !cell->hasParam(ID(RAM_INIT_FILE))) {
                    std::string fn = RTLIL::unescape_id(cell->name.str());
                    std::replace(fn.begin(), fn.end(), '\\', '_');
                    std::replace(fn.begin(), fn.end(), ':', '_');

                    while (used_filenames.count(fn))
                        fn += "_";

                    log("Setting parameter %s.RAM_DATA_FILE = %s\n",
                        log_id(cell->name), fn.c_str());
                    cell->setParam(ID(RAM_INIT_FILE), fn);
                }

                if (!cell->hasParam(ID(RAM_INIT_FILE))) {
                    log_warning("%s cell %s lacks RAM_DATA_FILE parameter, cell skipped.\n",
                                log_id(cell->type), log_id(cell));
                    continue;
                }
                // TODO: secure joining of the path parts
                std::string param_path = cell->getParam(ID(RAM_INIT_FILE)).decode_string();
                std::string path = dir_path.empty() ? param_path : (dir_path + "/" + param_path);

                int datalen = 36 * 1024;
                if (read) {
                    std::ifstream f;
                    f.open(path);
                    if (f.fail())
                        log_error("Failed to open file: %s\n", path.c_str());
                    Const data(State::Sx, datalen);
                    read_hex(path.c_str(), f, data);
                    cell->setParam(ID(RAM_INIT), data);
                }

                if (write) {
                    std::ofstream f;
                    f.open(path);
                    if (f.fail())
                        log_error("Failed to open file: %s\n", path.c_str());
                    Const data = cell->getParam(ID(RAM_INIT));
                    if (data.size() != datalen)
                        log_error("Invalid length of %s.RAM_INIT: %d\n", log_id(cell->name), data.size());
                    write_hex(path.c_str(), f, data);
                }
            }
        }
    }
} QlBramInitfilePass;

PRIVATE_NAMESPACE_END
