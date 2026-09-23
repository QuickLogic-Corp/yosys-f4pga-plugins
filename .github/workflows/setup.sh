#! /bin/bash
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

set -e

source .github/workflows/common.sh

if [ -z "${YOSYS_VERSION}" ] || [ -z "${YOSYS_PREFIX}" ]; then
	echo "Missing \${YOSYS_VERSION} or \${YOSYS_PREFIX} env value"
	exit 1
fi

##########################################################################

start_section Status
(
    set +e
    set -x
    git status
    git log --format=oneline -n 20 --graph
)
end_section

##########################################################################

# Built from source rather than conda: aurora2 builds these plugins against its
# yosys-gh submodule, and no conda channel publishes a matching Yosys.
start_section Install-Yosys
if [ -x "${YOSYS_PREFIX}/bin/yosys-config" ]; then
    echo "Yosys ${YOSYS_VERSION} restored from cache"
else
    git clone --depth 1 --branch "${YOSYS_VERSION}" --recurse-submodules --shallow-submodules \
        https://github.com/YosysHQ/yosys.git "${RUNNER_TEMP}/yosys-src"
    make -C "${RUNNER_TEMP}/yosys-src" -j`nproc` CONFIG=gcc PREFIX="${YOSYS_PREFIX}" install
fi
end_section

##########################################################################

start_section Yosys-Version
(
    export PATH="${YOSYS_PREFIX}/bin:$PATH"
    which yosys yosys-config
    yosys --version
    yosys-config --datdir
)
end_section
