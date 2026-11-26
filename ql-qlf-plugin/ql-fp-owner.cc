/*
 * Copyright 2026 QuickLogic Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

// ql_fp_owner: decides, inside synthesis, which RTL instance owns each atom of the netlist P&R
// consumes, and writes the owner table region-based placement reads (aurora2#1725).

#include "kernel/log.h"
#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/sigtools.h"

#include <algorithm>
#include <array>
#include <cstdint>
#include <fstream>
#include <functional>
#include <sstream>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// An owner is an RTL instance path as segments; the top module is the empty path. Encoded on
// attributes as hdlname does: segments joined by a blank. A cell may have several owners (a
// merged BRAM holding two memories); they are joined by a newline.
typedef std::vector<std::string> Owner;
typedef std::vector<Owner> Owners;

static const char *const kOwnerAttr = "\\ql_owner";
static const char *const kRuleAttr = "\\ql_owner_rule";
static const char *const kTreeAttr = "\\ql_fp_tree";
static const char *const kNamesAttr = "\\ql_fp_names";
static const char *const kBitsAttr = "\\ql_fp_bits";

static std::vector<std::string> split(const std::string &text, char sep)
{
    std::vector<std::string> parts;
    std::string current;
    for (char c : text) {
        if (c == sep) {
            parts.push_back(current);
            current.clear();
        } else {
            current += c;
        }
    }
    parts.push_back(current);
    return parts;
}

static Owner decode_owner(const std::string &text)
{
    Owner owner;
    if (text.empty())
        return owner;
    for (auto &segment : split(text, ' '))
        if (!segment.empty())
            owner.push_back(segment);
    return owner;
}

// hdlname is the cell's own path; its owner is that path without the last segment. A user
// attribute can leave it empty, which names no scope, so the owner is then the top.
static Owner hdlname_owner(const std::string &hdlname)
{
    Owner owner = decode_owner(hdlname);
    if (!owner.empty())
        owner.pop_back();
    return owner;
}

static std::string encode_owner(const Owner &owner)
{
    std::string text;
    for (auto &segment : owner)
        text += (text.empty() ? "" : " ") + segment;
    return text;
}

static Owners decode_owners(const std::string &text)
{
    Owners owners;
    for (auto &line : split(text, '\n'))
        owners.push_back(decode_owner(line));
    return owners;
}

static std::string encode_owners(Owners owners)
{
    std::sort(owners.begin(), owners.end());
    owners.erase(std::unique(owners.begin(), owners.end()), owners.end());
    std::string text;
    for (size_t i = 0; i < owners.size(); i++)
        text += (i ? "\n" : "") + encode_owner(owners[i]);
    return text;
}

static Owner common_ancestor(const Owners &owners)
{
    Owner common = owners.front();
    for (auto &owner : owners) {
        size_t n = 0;
        while (n < common.size() && n < owner.size() && common[n] == owner[n])
            n++;
        common.resize(n);
    }
    return common;
}

// write_blif's spelling of a name (backends/blif/blif.cc, str()).
static std::string blif_name(RTLIL::IdString id)
{
    std::string s = RTLIL::unescape_id(id);
    for (char &c : s)
        if (c == '#' || c == '=' || c == '<' || c == '>')
            c = '?';
    return s;
}

static std::string blif_bit_name(const RTLIL::SigBit &bit)
{
    if (bit.wire == nullptr)
        return bit == RTLIL::State::S1 ? "$true" : bit == RTLIL::State::S0 ? "$false" : "$undef";
    if (bit.wire->width == 1)
        return blif_name(bit.wire->name);
    int index = bit.wire->upto ? bit.wire->start_offset + bit.wire->width - bit.offset - 1 : bit.wire->start_offset + bit.offset;
    return stringf("%s[%d]", blif_name(bit.wire->name).c_str(), index);
}

// The scope flatten writes into a private name: $flatten\a.\b.$and$... -> [a, b]. Wrappers
// that later passes put in front of it ($techmap...) are skipped.
static bool scope_from_flatten_name(const std::string &name, Owner &owner)
{
    size_t at = name.find("$flatten\\");
    if (at == std::string::npos)
        return false;
    owner.clear();
    std::string rest = name.substr(at + 9);
    while (true) {
        size_t end = rest.find(".\\");
        size_t leaf = rest.find(".$");
        if (leaf != std::string::npos && (end == std::string::npos || leaf < end)) {
            owner.push_back(rest.substr(0, leaf));
            return true;
        }
        if (end == std::string::npos)
            return false;
        owner.push_back(rest.substr(0, end));
        rest = rest.substr(end + 2);
    }
}

// Minimal SHA-256 (FIPS 180-4), for the netlist hash the table is bound by.
static std::string sha256_hex(const std::string &data)
{
    static const uint32_t k[64] = {
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be,
      0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa,
      0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85,
      0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
      0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f,
      0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
    uint32_t h[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
    auto rotr = [](uint32_t x, int n) { return (x >> n) | (x << (32 - n)); };

    std::string msg = data;
    uint64_t bits = uint64_t(data.size()) * 8;
    msg += char(0x80);
    while (msg.size() % 64 != 56)
        msg += char(0);
    for (int i = 7; i >= 0; i--)
        msg += char((bits >> (8 * i)) & 0xff);

    for (size_t chunk = 0; chunk < msg.size(); chunk += 64) {
        uint32_t w[64];
        for (int i = 0; i < 16; i++)
            w[i] = (uint32_t(uint8_t(msg[chunk + 4 * i])) << 24) | (uint32_t(uint8_t(msg[chunk + 4 * i + 1])) << 16) |
                   (uint32_t(uint8_t(msg[chunk + 4 * i + 2])) << 8) | uint32_t(uint8_t(msg[chunk + 4 * i + 3]));
        for (int i = 16; i < 64; i++) {
            uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
            uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }
        uint32_t a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
        for (int i = 0; i < 64; i++) {
            uint32_t t1 = hh + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + k[i] + w[i];
            uint32_t t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            hh = g;
            g = f;
            f = e;
            e = d + t1;
            d = c;
            c = b;
            b = a;
            a = t1 + t2;
        }
        h[0] += a;
        h[1] += b;
        h[2] += c;
        h[3] += d;
        h[4] += e;
        h[5] += f;
        h[6] += g;
        h[7] += hh;
    }
    std::string hex;
    for (uint32_t v : h)
        hex += stringf("%08x", v);
    return hex;
}

static std::string json_string(const std::string &text)
{
    std::string out = "\"";
    for (unsigned char c : text) {
        if (c == '"' || c == '\\')
            out += std::string("\\") + char(c);
        else if (c < 0x20)
            out += stringf("\\u%04x", c);
        else
            out += char(c);
    }
    return out + "\"";
}

static std::string json_path(const Owner &owner)
{
    std::string out = "[";
    for (size_t i = 0; i < owner.size(); i++)
        out += (i ? ", " : "") + json_string(owner[i]);
    return out + "]";
}

// "name\toffset" -> owner of the bit's driver, and cell name -> owner, kept on the module so
// they survive the passes between -record and -assign.
struct Records {
    dict<std::string, Owner> bits;
    dict<std::string, Owner> names;

    // The attributes run to megabytes and each call used to parse them again. The last
    // records stay parsed here, under the exact text they came from, so a call whose text is
    // unchanged takes them instead.
    struct Parsed {
        std::string bits_text, names_text;
        dict<std::string, Owner> bits, names;
        bool valid = false;
    };
    static Parsed cache;

    std::string bits_text, names_text;

    static void load(const std::string &text, dict<std::string, Owner> &out)
    {
        for (auto &line : split(text, '\n')) {
            size_t tab = line.rfind('\t');
            if (tab != std::string::npos)
                out[line.substr(0, tab)] = decode_owner(line.substr(tab + 1));
        }
    }

    static std::string store(RTLIL::Module *module, const char *attr, const dict<std::string, Owner> &in)
    {
        std::string text;
        for (auto &it : in)
            text += it.first + "\t" + encode_owner(it.second) + "\n";
        module->set_string_attribute(attr, text);
        return text;
    }

    explicit Records(RTLIL::Module *module) : bits_text(module->get_string_attribute(kBitsAttr)), names_text(module->get_string_attribute(kNamesAttr))
    {
        if (cache.valid && cache.bits_text == bits_text && cache.names_text == names_text) {
            bits = std::move(cache.bits);
            names = std::move(cache.names);
        } else {
            load(bits_text, bits);
            load(names_text, names);
        }
        cache = Parsed();
    }

    void save(RTLIL::Module *module)
    {
        bits_text = store(module, kBitsAttr, bits);
        names_text = store(module, kNamesAttr, names);
    }

    // Hand the records back with the text they now match: the loaded one, or the saved one.
    // Only record() changes them, and it saves before it returns.
    ~Records()
    {
        cache.bits_text = std::move(bits_text);
        cache.names_text = std::move(names_text);
        cache.bits = std::move(bits);
        cache.names = std::move(names);
        cache.valid = true;
    }
};

Records::Parsed Records::cache;

static std::string bit_key(const RTLIL::SigBit &bit) { return stringf("%s\t%d", bit.wire->name.c_str(), bit.offset); }

struct OwnerWorker {
    RTLIL::Module *module;
    SigMap sigmap;
    Records records;
    dict<RTLIL::SigBit, RTLIL::Cell *> driver;
    dict<RTLIL::SigBit, pool<RTLIL::Cell *>> readers;
    dict<RTLIL::SigBit, std::vector<RTLIL::SigBit>> aliases;

    explicit OwnerWorker(RTLIL::Module *module) : module(module), sigmap(module), records(module)
    {
        for (auto wire : module->wires())
            for (auto bit : RTLIL::SigSpec(wire))
                aliases[sigmap(bit)].push_back(bit);
        for (auto cell : module->cells())
            for (auto &conn : cell->connections())
                for (auto bit : sigmap(conn.second)) {
                    if (bit.wire == nullptr)
                        continue;
                    if (cell->output(conn.first))
                        driver[bit] = cell;
                    else
                        readers[bit].insert(cell);
                }
    }

    static bool has_owner(RTLIL::Cell *cell) { return cell->has_attribute(kOwnerAttr); }
    static Owners owners_of(RTLIL::Cell *cell) { return decode_owners(cell->get_string_attribute(kOwnerAttr)); }

    static void set_owner(RTLIL::Cell *cell, const Owners &owners, const char *rule)
    {
        cell->set_string_attribute(kOwnerAttr, encode_owners(owners));
        cell->set_string_attribute(kRuleAttr, rule);
    }

    // Steps 2 and 3 of the rule: what the cell itself, or its output, still says.
    bool recorded_owner(RTLIL::Cell *cell, Owner &owner)
    {
        if (cell->has_attribute(ID::hdlname)) {
            owner = hdlname_owner(cell->get_string_attribute(ID::hdlname));
            return true;
        }
        if (cell->has_attribute(ID(scopename))) {
            owner = decode_owner(cell->get_string_attribute(ID(scopename)));
            return true;
        }
        // A techmap child is named after the cell it replaced: \P.child or $techmap\P.$child.
        std::string name = cell->name.str();
        while (name.compare(0, 8, "$techmap") == 0)
            name = name.substr(8);
        for (size_t dot = name.rfind('.'); dot != std::string::npos && dot > 0; dot = name.rfind('.', dot - 1)) {
            auto it = records.names.find(name.substr(0, dot));
            if (it != records.names.end()) {
                owner = it->second;
                return true;
            }
        }
        if (scope_from_flatten_name(cell->name.str(), owner))
            return true;
        for (auto &conn : cell->connections()) {
            if (!cell->output(conn.first))
                continue;
            for (auto bit : sigmap(conn.second)) {
                if (bit.wire == nullptr)
                    continue;
                for (auto &alias : aliases[bit]) {
                    auto it = records.bits.find(bit_key(alias));
                    if (it != records.bits.end()) {
                        owner = it->second;
                        return true;
                    }
                }
            }
        }
        return false;
    }

    // Steps 4 and 5: the owners nearest along the fanout (or fanin), as their deepest common
    // ancestor. Only owners decided by steps 1 to 3 count, so the order cells are visited in
    // cannot change the answer.
    bool inferred_owner(RTLIL::Cell *start, bool fanout, const pool<RTLIL::Cell *> &decided, Owner &owner)
    {
        pool<RTLIL::Cell *> seen{start};
        std::vector<RTLIL::Cell *> frontier{start};
        const size_t limit = 100000;
        while (!frontier.empty() && seen.size() < limit) {
            std::vector<RTLIL::Cell *> next;
            for (auto cell : frontier)
                for (auto &conn : cell->connections()) {
                    if (cell->output(conn.first) != fanout)
                        continue;
                    for (auto bit : sigmap(conn.second)) {
                        if (bit.wire == nullptr)
                            continue;
                        if (fanout) {
                            for (auto reader : readers[bit])
                                if (seen.insert(reader).second)
                                    next.push_back(reader);
                        } else if (driver.count(bit) && seen.insert(driver.at(bit)).second) {
                            next.push_back(driver.at(bit));
                        }
                    }
                }
            Owners found;
            for (auto cell : next)
                if (decided.count(cell))
                    for (auto &o : owners_of(cell))
                        found.push_back(o);
            if (!found.empty()) {
                owner = common_ancestor(found);
                return true;
            }
            frontier = next;
        }
        return false;
    }

    // The rule, for every cell that has no owner yet.
    void assign(dict<std::string, int> &counts)
    {
        pool<RTLIL::Cell *> decided;
        std::vector<RTLIL::Cell *> open;
        for (auto cell : module->cells()) {
            Owner owner;
            if (has_owner(cell)) {
                decided.insert(cell);
            } else if (recorded_owner(cell, owner)) {
                set_owner(cell, {owner}, "recorded");
                decided.insert(cell);
                counts["recorded"]++;
            } else {
                open.push_back(cell);
            }
        }
        std::sort(open.begin(), open.end(), [](RTLIL::Cell *a, RTLIL::Cell *b) { return a->name.str() < b->name.str(); });
        dict<RTLIL::Cell *, std::pair<Owner, const char *>> inferred;
        for (auto cell : open) {
            Owner owner;
            if (inferred_owner(cell, true, decided, owner))
                inferred[cell] = {owner, "inferred_fanout"};
            else if (inferred_owner(cell, false, decided, owner))
                inferred[cell] = {owner, "inferred_fanin"};
            else
                inferred[cell] = {Owner{}, "top"};
        }
        for (auto &it : inferred) {
            set_owner(it.first, {it.second.first}, it.second.second);
            counts[it.second.second]++;
        }
    }

    // Owners right after flatten, and what each driven bit and cell name was owned by then.
    void record()
    {
        // Right after flatten a cell with no scope is the top module's own logic; later, a cell
        // nothing records is left for -assign to infer.
        const bool after_flatten = records.names.empty() && records.bits.empty();
        for (auto cell : module->cells()) {
            Owner owner;
            if (!has_owner(cell)) {
                if (recorded_owner(cell, owner))
                    set_owner(cell, {owner}, "recorded");
                else if (after_flatten)
                    set_owner(cell, {Owner{}}, "recorded");
                else
                    continue;
            }
            Owners owners = owners_of(cell);
            if (owners.size() != 1)
                continue;
            if (!records.names.count(cell->name.str()))
                records.names[cell->name.str()] = owners.front();
            for (auto &conn : cell->connections()) {
                if (!cell->output(conn.first))
                    continue;
                for (auto bit : sigmap(conn.second)) {
                    if (bit.wire == nullptr)
                        continue;
                    for (auto &alias : aliases[bit])
                        if (!records.bits.count(bit_key(alias)))
                            records.bits[bit_key(alias)] = owners.front();
                }
            }
        }
        records.save(module);
    }
};

// The instance tree before flatten, as "segment segment\tmodule" lines on the top module.
static void record_tree(RTLIL::Design *design, RTLIL::Module *top)
{
    std::vector<std::string> lines;
    std::function<void(RTLIL::Module *, const Owner &)> walk = [&](RTLIL::Module *module, const Owner &prefix) {
        for (auto cell : module->cells()) {
            RTLIL::Module *child = design->module(cell->type);
            if (child == nullptr || child->get_blackbox_attribute())
                continue;
            Owner path = prefix;
            path.push_back(RTLIL::unescape_id(cell->name));
            std::string name = child->name.str();
            if (child->has_attribute(ID::hdlname))
                name = child->get_string_attribute(ID::hdlname);
            else if (name.compare(0, 8, "$paramod") == 0)
                name = split(name.substr(name.find('\\') + 1), '\\').front();
            else
                name = RTLIL::unescape_id(child->name);
            lines.push_back(encode_owner(path) + "\t" + name);
            walk(child, path);
        }
    };
    walk(top, {});
    // Already flat (a front end or an earlier pass flattened it): the scopes the cells name.
    if (lines.empty()) {
        pool<std::string> scopes;
        for (auto cell : top->cells()) {
            Owner owner;
            if (cell->has_attribute(ID::hdlname)) {
                owner = hdlname_owner(cell->get_string_attribute(ID::hdlname));
            } else if (cell->has_attribute(ID(scopename))) {
                owner = decode_owner(cell->get_string_attribute(ID(scopename)));
            }
            for (size_t n = 1; n <= owner.size(); n++)
                scopes.insert(encode_owner(Owner(owner.begin(), owner.begin() + n)));
        }
        for (auto &scope : scopes)
            lines.push_back(scope + "\t");
    }
    std::sort(lines.begin(), lines.end());
    lines.erase(std::unique(lines.begin(), lines.end()), lines.end());
    std::string text;
    for (auto &line : lines)
        text += line + "\n";
    top->set_string_attribute(kTreeAttr, text);
}

// VPR names a .names block after its output net first and renames it from .cname after; if
// that name is already taken it aborts. So a cell name must not equal a net, a port, an out:
// pad or, as write_blif spells it (\x<y and \x>y are both x?y), another cell's name. A clash
// gets a fixed suffix, in sorted-name order, so the result is stable.
static int guard_names(RTLIL::Module *module)
{
    pool<std::string> taken;
    for (auto wire : module->wires())
        for (auto bit : RTLIL::SigSpec(wire)) {
            taken.insert(blif_bit_name(bit));
            if (wire->port_output)
                taken.insert("out:" + blif_bit_name(bit));
        }
    std::vector<RTLIL::Cell *> cells = module->cells();
    std::sort(cells.begin(), cells.end(), [](RTLIL::Cell *a, RTLIL::Cell *b) { return a->name.str() < b->name.str(); });
    std::vector<RTLIL::Cell *> clashing;
    pool<std::string> cell_names;
    for (auto cell : cells) {
        std::string name = blif_name(cell->name);
        if (taken.count(name) || cell_names.count(name))
            clashing.push_back(cell);
        cell_names.insert(name);
    }
    int suffix = 0;
    for (auto cell : clashing) {
        std::string base = RTLIL::unescape_id(cell->name);
        std::string name;
        do
            name = stringf("%s$fp%d", base.c_str(), ++suffix);
        while (taken.count(blif_name(RTLIL::escape_id(name))) || cell_names.count(blif_name(RTLIL::escape_id(name))) ||
               module->cell(RTLIL::escape_id(name)));
        log("Renaming %s to %s: its BLIF name is also a net, port, pad or cell name\n", log_id(cell->name), name.c_str());
        cell_names.insert(blif_name(RTLIL::escape_id(name)));
        module->rename(cell, RTLIL::escape_id(name));
    }
    return GetSize(clashing);
}

struct BlifAtom {
    std::string name;
    std::string type;
    std::string output;
    std::vector<std::string> inputs;
    std::vector<std::pair<std::string, std::string>> pins;
    bool is_names = false;
    bool named = false;
};

// The atoms of the top model of a BLIF, named as VPR names them: the .cname when there is
// one, else the output net. A .subckt without .cname is named by write_table, which knows
// its port directions.
static std::vector<BlifAtom> read_blif_atoms(const std::string &text, const std::string &top)
{
    std::vector<BlifAtom> atoms;
    std::istringstream in(text);
    std::string raw, line;
    bool in_model = false;
    while (std::getline(in, raw)) {
        if (!raw.empty() && raw.back() == '\r')
            raw.pop_back();
        if (!raw.empty() && raw.back() == '\\') {
            line += raw.substr(0, raw.size() - 1) + " ";
            continue;
        }
        line += raw;
        std::istringstream words(line);
        line.clear();
        std::vector<std::string> tokens;
        for (std::string word; words >> word;)
            tokens.push_back(word);
        if (tokens.empty())
            continue;
        const std::string &cmd = tokens.front();
        if (cmd == ".model") {
            in_model = tokens.size() >= 2 && tokens[1] == top;
        } else if (!in_model) {
            continue;
        } else if (cmd == ".end") {
            in_model = false;
        } else if (cmd == ".names" && tokens.size() >= 2) {
            BlifAtom atom;
            atom.is_names = true;
            atom.output = tokens.back();
            atom.inputs.assign(tokens.begin() + 1, tokens.end() - 1);
            atom.name = atom.output;
            atoms.push_back(atom);
        } else if ((cmd == ".subckt" || cmd == ".gate") && tokens.size() >= 2) {
            BlifAtom atom;
            atom.type = tokens[1];
            for (size_t i = 2; i < tokens.size(); i++) {
                size_t eq = tokens[i].find('=');
                if (eq != std::string::npos) {
                    atom.inputs.push_back(tokens[i].substr(eq + 1));
                    atom.pins.push_back({tokens[i].substr(0, eq), tokens[i].substr(eq + 1)});
                }
            }
            atoms.push_back(atom);
        } else if (cmd == ".latch" && tokens.size() >= 3) {
            BlifAtom atom;
            atom.inputs.push_back(tokens[1]);
            if (tokens.size() >= 5)
                atom.inputs.push_back(tokens[4]);
            atom.output = atom.name = tokens[2];
            atoms.push_back(atom);
        } else if (cmd == ".cname" && tokens.size() >= 2 && !atoms.empty()) {
            atoms.back().name = tokens[1];
            atoms.back().named = true;
        }
    }
    return atoms;
}

// VPR sweeps a block none of whose outputs has a sink, pass after pass until nothing more goes,
// so such an atom is not in the .net. A .subckt whose cell is unknown is kept, its pins taken
// for inputs.
static std::vector<bool> vpr_swept(const std::vector<BlifAtom> &atoms, const std::vector<RTLIL::Cell *> &cells, const pool<std::string> &top_outputs)
{
    const size_t n = atoms.size();
    std::vector<std::vector<std::string>> ins(n), outs(n);
    std::vector<bool> keep(n, false), swept(n, false);
    for (size_t i = 0; i < n; i++) {
        if (atoms[i].type.empty()) {
            ins[i] = atoms[i].inputs;
            outs[i] = {atoms[i].output};
            continue;
        }
        for (auto &pin : atoms[i].pins) {
            const std::string port = pin.first.substr(0, pin.first.find('['));
            (cells[i] && cells[i]->output(RTLIL::escape_id(port)) ? outs[i] : ins[i]).push_back(pin.second);
        }
        keep[i] = !cells[i];
    }
    dict<std::string, int> sinks;
    for (auto &net : top_outputs)
        sinks[net]++;
    for (size_t i = 0; i < n; i++)
        for (auto &net : ins[i])
            sinks[net]++;
    for (bool changed = true; changed;) {
        changed = false;
        for (size_t i = 0; i < n; i++) {
            if (swept[i] || keep[i])
                continue;
            if (std::any_of(outs[i].begin(), outs[i].end(), [&](const std::string &net) { return sinks.count(net) && sinks.at(net) > 0; }))
                continue;
            swept[i] = changed = true;
            for (auto &net : ins[i])
                sinks[net]--;
        }
    }
    return swept;
}

static void write_table(RTLIL::Module *module, const std::string &table_file, const std::string &blif_file, const std::string &front_end)
{
    std::ifstream blif_in(blif_file, std::ios::binary);
    if (!blif_in)
        log_error("ql_fp_owner: cannot read %s\n", blif_file.c_str());
    std::string blif((std::istreambuf_iterator<char>(blif_in)), std::istreambuf_iterator<char>());

    OwnerWorker worker(module);
    dict<std::string, int> late;
    worker.assign(late);
    for (auto &it : late)
        log("%s since -assign: %d cell(s)\n", it.first.c_str(), it.second);

    dict<std::string, RTLIL::Cell *> by_name;
    dict<std::string, RTLIL::Cell *> net_driver;
    for (auto cell : module->cells()) {
        by_name[blif_name(cell->name)] = cell;
        for (auto &conn : cell->connections())
            if (cell->output(conn.first))
                for (auto bit : conn.second)
                    for (auto &alias : worker.aliases[worker.sigmap(bit)])
                        net_driver[blif_bit_name(alias)] = cell;
    }

    struct Row {
        std::string name, type, rule;
        Owners owners;
    };
    std::vector<Row> rows;
    dict<std::string, int> counts;
    std::vector<BlifAtom> atoms = read_blif_atoms(blif, blif_name(module->name));
    std::vector<RTLIL::Cell *> cells(atoms.size(), nullptr);
    for (size_t i = 0; i < atoms.size(); i++) {
        BlifAtom &atom = atoms[i];
        RTLIL::Cell *&cell = cells[i];
        if (atom.named) {
            auto it = by_name.find(atom.name);
            if (it != by_name.end())
                cell = it->second;
        } else if (atom.type.empty() && !atom.inputs.empty()) {
            // Without .cname (-no_iname, -rel_ip_blif) a .names or .latch is the cell driving
            // its output net -- unless it is a buffer write_blif added, whose input that same
            // cell drives.
            auto drv = net_driver.find(atom.output);
            if (drv != net_driver.end()) {
                auto in = net_driver.find(atom.inputs.front());
                const bool buffer = atom.is_names && atom.inputs.size() == 1 && in != net_driver.end() && in->second == drv->second;
                if (!buffer)
                    cell = drv->second;
            }
        } else if (!atom.type.empty()) {
            // Without .cname (-rel_ip_blif) VPR names a .subckt after the net on its first
            // output pin.
            for (auto &pin : atom.pins) {
                auto drv = net_driver.find(pin.second);
                if (drv == net_driver.end() || RTLIL::unescape_id(drv->second->type) != atom.type)
                    continue;
                const std::string port = pin.first.substr(0, pin.first.find('['));
                if (drv->second->output(RTLIL::escape_id(port))) {
                    cell = drv->second;
                    atom.name = pin.second;
                    break;
                }
            }
        }
    }
    pool<std::string> top_outputs;
    for (auto wire : module->wires())
        if (wire->port_output)
            for (auto bit : RTLIL::SigSpec(wire))
                top_outputs.insert(blif_bit_name(bit));
    const std::vector<bool> swept = vpr_swept(atoms, cells, top_outputs);
    for (size_t i = 0; i < atoms.size(); i++) {
        if (swept[i])
            continue;
        const BlifAtom &atom = atoms[i];
        RTLIL::Cell *cell = cells[i];
        Row row;
        row.name = atom.name;
        if (cell) {
            row.type = RTLIL::unescape_id(cell->type);
            row.owners = OwnerWorker::owners_of(cell);
            row.rule = cell->get_string_attribute(kRuleAttr);
        } else if (atom.is_names && atom.inputs.empty()) {
            row.type = "$const";
            row.owners = {Owner{}};
            row.rule = "top";
        } else {
            // A buffer write_blif adds for a connection: owned with what drives it.
            row.type = atom.is_names ? "$lut" : "";
            auto drv = atom.inputs.empty() ? net_driver.end() : net_driver.find(atom.inputs.front());
            if (drv != net_driver.end()) {
                row.owners = OwnerWorker::owners_of(drv->second);
                row.rule = "inferred_fanin";
            } else {
                row.owners = {Owner{}};
                row.rule = "top";
            }
        }
        counts[row.rule]++;
        rows.push_back(row);
    }
    std::sort(rows.begin(), rows.end(), [](const Row &a, const Row &b) { return a.name < b.name; });

    std::vector<std::pair<Owner, std::string>> instances;
    for (auto &line : split(module->get_string_attribute(kTreeAttr), '\n')) {
        size_t tab = line.find('\t');
        if (tab != std::string::npos)
            instances.push_back({decode_owner(line.substr(0, tab)), line.substr(tab + 1)});
    }
    std::sort(instances.begin(), instances.end());

    std::ofstream out(table_file);
    if (!out)
        log_error("ql_fp_owner: cannot write %s\n", table_file.c_str());
    out << "{\n";
    out << "  \"schema_version\": 2,\n";
    out << "  \"netlist_sha256\": " << json_string(sha256_hex(blif)) << ",\n";
    out << "  \"front_end\": " << json_string(front_end) << ",\n";
    out << "  \"top\": " << json_string(RTLIL::unescape_id(module->name)) << ",\n";
    out << "  \"instances\": [";
    for (size_t i = 0; i < instances.size(); i++)
        out << (i ? ",\n" : "\n") << "    {\"path\": " << json_path(instances[i].first) << ", \"module\": " << json_string(instances[i].second)
            << "}";
    out << "\n  ],\n";
    out << "  \"atoms\": [";
    for (size_t i = 0; i < rows.size(); i++) {
        std::string owners;
        for (size_t j = 0; j < rows[i].owners.size(); j++)
            owners += (j ? ", " : "") + json_path(rows[i].owners[j]);
        out << (i ? ",\n" : "\n") << "    {\"name\": " << json_string(rows[i].name) << ", \"type\": " << json_string(rows[i].type)
            << ", \"owners\": [" << owners << "], \"rule\": " << json_string(rows[i].rule) << "}";
    }
    out << "\n  ]\n}\n";

    log("Wrote %d atom(s) and %d instance(s) to %s:", GetSize(rows), GetSize(instances), table_file.c_str());
    for (auto rule : {"recorded", "inferred_fanout", "inferred_fanin", "top"})
        log(" %s %d", rule, counts.count(rule) ? counts.at(rule) : 0);
    log("; left out %d atom(s) VPR sweeps\n", int(std::count(swept.begin(), swept.end(), true)));
}

struct QlFpOwnerPass : public Pass {
    QlFpOwnerPass() : Pass("ql_fp_owner", "records which RTL instance owns each atom (region-based placement)") {}

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    ql_fp_owner -tree | -record | -assign | -guard\n");
        log("    ql_fp_owner -write <table> -blif <file> [-front_end <name>]\n");
        log("\n");
        log("Decides which RTL instance owns each atom of the netlist, by one rule, and writes\n");
        log("the owner table region-based placement reads. synth_quicklogic -owner_table runs\n");
        log("the modes at these points:\n");
        log("\n");
        log("    -tree\n");
        log("        before flatten: records the instance tree on the top module.\n");
        log("\n");
        log("    -record\n");
        log("        after flatten -scopename: stamps each cell with the \\ql_owner attribute\n");
        log("        and records the owner of each driven bit and cell name, so later passes\n");
        log("        that rename or replace cells cannot lose it. May run again later, before\n");
        log("        a pass that replaces owned cells; existing records are kept, and a cell\n");
        log("        nothing records is left for -assign.\n");
        log("\n");
        log("    -assign\n");
        log("        after abc, before autoname: gives each cell without an owner one, by\n");
        log("        the first of these that applies:\n");
        log("          recorded         \\ql_owner; hdlname or scopename; the cell it was\n");
        log("                           mapped from; a $flatten\\ name; the owner recorded\n");
        log("                           for its output bit\n");
        log("          inferred_fanout  the nearest owned cells it drives (their deepest\n");
        log("                           common ancestor)\n");
        log("          inferred_fanin   the nearest owned cells driving it, the same way\n");
        log("          top              the top module\n");
        log("\n");
        log("    -guard\n");
        log("        before the final write_blif: renames each cell whose BLIF name is also a\n");
        log("        net, port, out: pad or earlier cell name, which VPR aborts on, with a $fpN\n");
        log("        suffix.\n");
        log("\n");
        log("    -write <table> -blif <file>\n");
        log("        after the final write_blif: writes the owner table (schema version 2)\n");
        log("        for the atoms of <file>, named as VPR names them, with its sha256.\n");
        log("        An atom VPR sweeps, one whose outputs drive nothing, is left out.\n");
        log("        Cells created since -assign get an owner first.\n");
        log("\n");
    }

    void execute(std::vector<std::string> args, RTLIL::Design *design) override
    {
        log_header(design, "Executing QL_FP_OWNER pass.\n");
        std::string mode, table_file, blif_file, front_end = "yosys";
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-tree" || args[argidx] == "-record" || args[argidx] == "-assign" || args[argidx] == "-guard") {
                mode = args[argidx];
            } else if (args[argidx] == "-write" && argidx + 1 < args.size()) {
                mode = "-write";
                table_file = args[++argidx];
            } else if (args[argidx] == "-blif" && argidx + 1 < args.size()) {
                blif_file = args[++argidx];
            } else if (args[argidx] == "-front_end" && argidx + 1 < args.size()) {
                front_end = args[++argidx];
            } else {
                break;
            }
        }
        extra_args(args, argidx, design);
        if (mode.empty())
            log_cmd_error("ql_fp_owner: give one of -tree, -record, -assign, -guard, -write\n");
        if (mode == "-write" && blif_file.empty())
            log_cmd_error("ql_fp_owner -write needs -blif <file>\n");

        RTLIL::Module *top = design->top_module();
        if (top == nullptr)
            log_cmd_error("ql_fp_owner: the design has no top module\n");

        if (mode == "-tree") {
            record_tree(design, top);
        } else if (mode == "-record") {
            OwnerWorker(top).record();
        } else if (mode == "-assign") {
            dict<std::string, int> counts;
            OwnerWorker(top).assign(counts);
            for (auto &it : counts)
                log("%s: %d cell(s)\n", it.first.c_str(), it.second);
        } else if (mode == "-guard") {
            log("%d cell(s) renamed\n", guard_names(top));
        } else {
            write_table(top, table_file, blif_file, front_end);
        }
    }
} QlFpOwnerPass;

PRIVATE_NAMESPACE_END
