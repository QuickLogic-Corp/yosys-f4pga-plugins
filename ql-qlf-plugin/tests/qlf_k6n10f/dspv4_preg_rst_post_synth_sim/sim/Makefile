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

# The RTL and every netlist go into one simulation, so a single run compares
# both designs against their source.
TESTBENCH = dspv4_preg_rst_post_synth_sim_tb.v
RTL = ../dspv4_preg_rst_post_synth_sim.v
POST_SYNTH = $(wildcard *_post_synth.v)
SIM_LIBS = $(shell find ../../../../qlf_k6n10f -name "*.v" -not -name "*_map.v")

sim:
	@iverilog -g2012 -o sim.vvp $(TESTBENCH) $(RTL) $(POST_SYNTH) $(SIM_LIBS) > sim.vvp.log 2>&1
	@vvp sim.vvp > sim.log 2>&1 || (tail -20 sim.log; false)
	@grep -q 'MISMATCH' sim.log && (grep 'MISMATCH\|RESULT' sim.log; false) || grep 'RESULT' sim.log
