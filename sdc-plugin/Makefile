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

PLUGIN_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

NAME = sdc
SOURCES = buffers.cc \
          clocks.cc \
          propagation.cc \
          sdc.cc \
          sdc_writer.cc \
          set_false_path.cc \
          set_max_delay.cc \
          set_clock_groups.cc
include ../Makefile_plugin.common

# sdc.cc includes <tcl.h>; Yosys >= 0.67's CMake yosys-config no longer passes its include path.
ifeq ($(origin TCL_CFLAGS),undefined)
TCL_CFLAGS := $(shell pkg-config --cflags tcl 2>/dev/null)
endif
ifeq ($(strip $(TCL_CFLAGS)),)
$(warning pkg-config found no Tcl: install pkg-config and the Tcl development package (tcl-dev, tcl-devel or mingw-w64-x86_64-tcl), or set TCL_CFLAGS=-I<tcl include dir>)
endif
CXXFLAGS += $(TCL_CFLAGS)

# A Windows DLL must resolve Tcl at link time; that yosys-config no longer adds -ltcl86 either.
ifneq ($(findstring mingw,$(shell $(CXX) -dumpmachine 2>/dev/null)),)
ifeq ($(origin TCL_LIBS),undefined)
TCL_LIBS := $(shell pkg-config --libs tcl 2>/dev/null)
endif
ifeq ($(strip $(TCL_LIBS)),)
$(warning pkg-config found no Tcl libraries: install mingw-w64-x86_64-tcl, or set TCL_LIBS=-L<dir> -ltcl86)
endif
LDLIBS += $(TCL_LIBS)
endif
