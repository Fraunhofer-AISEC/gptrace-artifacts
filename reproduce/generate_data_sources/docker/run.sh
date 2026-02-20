#!/usr/bin/env bash
# Copyright 2025 Fraunhofer AISEC
# Fraunhofer-Gesellschaft zur Förderung der angewandten Forschung e.V.
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

# Collect data

source /project/gptrace/.venv/bin/activate
source /project/env_variables.sh
PROG_TIMEOUT="${PROG_TIMEOUT:-120}"
PROG_WORKERS="${PROG_WORKERS:-128}"

ACTUAL_WORKERS="${1:-${PROG_WORKERS}}"

python3 rename.py --rename_inputs

# If some crashes fail to reproduce, try switching the ASAN_OPTIONS and enable LSAN_OPTIONS
export ASAN_OPTIONS=abort_on_error=1:detect_leaks=0:handle_abort=1
#export ASAN_OPTIONS=abort_on_error=1:symbolize=0:allocator_may_return_null=1
#export LSAN_OPTIONS=verbosity=1:log_threads=1:use_tls=0

python3 /project/gptrace/src/collect_data/collect_data.py -c /project/clean_inputs -t ${PROG_TIMEOUT} -o /project/clean_traces -j ${ACTUAL_WORKERS} --verify_crash -v -l /project/out/collect_data.log -- ${PROG_BIN} ${PROG_PREFIX} @@ ${PROG_POSTFIX}

python3 rename.py
