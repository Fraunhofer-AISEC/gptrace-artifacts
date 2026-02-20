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

# Collect Crashwalk databases

source /project/gptrace/.venv/bin/activate
source /project/env_variables.sh

PROG_WORKERS="${PROG_WORKERS:-128}"
PROG_TIMEOUT="${PROG_TIMEOUT:-120}"

ACTUAL_WORKERS="${1:-${PROG_WORKERS}}"
ACTUAL_TIMEOUT="${2:-${PROG_TIMEOUT}}"

LOGFILE=/project/out/crashwalk.log

# If some crashes fail to reproduce, try switching the ASAN_OPTIONS and enable LSAN_OPTIONS
export ASAN_OPTIONS=abort_on_error=1:detect_leaks=0:handle_abort=1
#export ASAN_OPTIONS=abort_on_error=1:symbolize=0:allocator_may_return_null=1
#export LSAN_OPTIONS=verbosity=1:log_threads=1:use_tls=0

export GOMAXPROCS="${ACTUAL_WORKERS}"
/project/crashwalk/bin/cwtriage -root /project/inputs -t ${ACTUAL_TIMEOUT} -seendb /project/out/crashwalk.db -workers ${ACTUAL_WORKERS} -- ${PROG_BIN} ${PROG_PREFIX} @@ ${PROG_POSTFIX} >"${LOGFILE}" 2>&1

echo "" >>"${LOGFILE}"
echo "Running ground truth analysis on crashwalk results" >>"${LOGFILE}"
python3 /project/crashwalk/crashwalk_gta.py /project/out/crashwalk.db >/project/out/crashwalk_results 2>&1
