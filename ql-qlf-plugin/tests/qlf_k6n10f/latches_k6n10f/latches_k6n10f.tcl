# Copyright 2020-2022 F4PGA Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

# Split out of dffs; fails until the owner confirms qlf_k6n10f dropped latches on purpose.

yosys -import
if { [info procs quicklogic_eqn] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands

read_verilog $::env(DESIGN_TOP).v
design -save read

# =============================================================================
# qlf_k6n10f (with synchronous S/R flip-flops)

# LATCH
design -load read
hierarchy -top my_latch
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latch
design -load postopt
yosys cd my_latch
stat
select -assert-count 1 t:latchsre

# LATCHN
design -load read
hierarchy -top my_latchn
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchn
design -load postopt
yosys cd my_latchn
stat
select -assert-count 1 t:latchnsre

# =============================================================================
# qlf_k6n10f (no synchronous S/R flip-flops)

# LATCH
design -load read
hierarchy -top my_latch
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latch -nosdff
design -load postopt
yosys cd my_latch
stat
select -assert-count 1 t:latchsre

# LATCHN
design -load read
hierarchy -top my_latchn
yosys proc
equiv_opt -assert -async2sync -map +/quicklogic/qlf_k6n10f/cells_sim.v synth_ql -family qlf_k6n10f -top my_latchn -nosdff
design -load postopt
yosys cd my_latchn
stat
select -assert-count 1 t:latchnsre
