/*
 * Copyright 2020-2022 F4PGA Authors
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
 *
 */

#include "UhdmAst.h"
#include "frontends/ast/ast.h"
#include "kernel/yosys.h"
#include "uhdm/SynthSubset.h"
#include "uhdm/VpiListener.h"
#include <string>
#include <type_traits>
#include <vector>

namespace systemverilog_plugin
{

// FIXME (mglb): temporary fix to support UHDM both before and after the following change:
// https://github.com/chipsalliance/UHDM/commit/d78d094448bd94926644e48adea4df293b82f101
// The commit introducing this code should to be reverted after Surelog is bumped to recent versions in all our repositories.
template <typename ObjT, typename... ArgN, std::enable_if_t<std::is_constructible_v<ObjT, ArgN...>, bool> = true>
static inline ObjT *make_new_object_with_optional_extra_true_arg(ArgN &&... arg_n)
{
    // Older UHDM version
    return new ObjT(std::forward<ArgN>(arg_n)...);
}

template <typename ObjT, typename... ArgN, std::enable_if_t<!std::is_constructible_v<ObjT, ArgN...> && std::is_constructible_v<ObjT, ArgN..., bool>, bool> = true>
static inline ObjT *make_new_object_with_optional_extra_true_arg(ArgN &&... arg_n)
{
    // Newer UHDM version
    return new ObjT(std::forward<ArgN>(arg_n)..., true);
}

// UHDM::SynthSubset later gained a `design*` parameter ahead of the trailing
// bool(s) (feeds the `design_` member, currently unused by SynthSubset
// itself). Neither branch above can express inserting an argument in the
// middle of the pack, so this is a dedicated third case rather than a
// generalization of the other two.
template <typename ObjT, typename Arg0, typename Arg1, typename Arg2,
          std::enable_if_t<!std::is_constructible_v<ObjT, Arg0, Arg1, Arg2> && !std::is_constructible_v<ObjT, Arg0, Arg1, Arg2, bool> &&
                                std::is_constructible_v<ObjT, Arg0, Arg1, std::nullptr_t, Arg2, bool>,
                            bool> = true>
static inline ObjT *make_new_object_with_optional_extra_true_arg(Arg0 &&arg0, Arg1 &&arg1, Arg2 &&arg2)
{
    // Newest UHDM version: `design*` inserted before the trailing bool(s)
    return new ObjT(std::forward<Arg0>(arg0), std::forward<Arg1>(arg1), nullptr, std::forward<Arg2>(arg2), true);
}

struct UhdmCommonFrontend : public ::Yosys::Frontend {
    UhdmAstShared shared;
    std::string report_directory;
    std::vector<std::string> args;
    UhdmCommonFrontend(std::string name, std::string short_help) : Frontend(name, short_help) {}
    virtual void print_read_options();
    virtual void help() = 0;
    virtual ::Yosys::AST::AstNode *parse(std::string filename) = 0;
    virtual void call_log_header(::Yosys::RTLIL::Design *design) = 0;
    void execute(std::istream *&f, std::string filename, std::vector<std::string> args, ::Yosys::RTLIL::Design *design);
};

} // namespace systemverilog_plugin
