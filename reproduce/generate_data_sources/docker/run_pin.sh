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

# Collect full execution traces with Intel PIN

source /project/env_variables.sh

PROG_ARGS="${PROG_PREFIX} @@ ${PROG_POSTFIX}"
if [ -z "${PROG_ARGS}" ]; then
    PROG_ARGS="@@"
fi

INPUT_PATH="${1}"
OUTPUT_PATH="${2}"

PROG_TIMEOUT="${PROG_TIMEOUT:-120}"
ACTUAL_TIMEOUT="${3:-${PROG_TIMEOUT}}"

ARGS_WITH_INPUT="${PROG_ARGS//@@/${INPUT_PATH}}"
echo "Tracing /project/binary ${ARGS_WITH_INPUT}"

timeout --signal=9 "${ACTUAL_TIMEOUT}" /project/pin-3.31/pin -t /project/default/bbl_tracing.so -o "${OUTPUT_PATH}" -- /project/binary ${ARGS_WITH_INPUT}
EXITCODE=$?
if [ ${EXITCODE} -eq 124 ] || [ ${EXITCODE} -eq 137 ]; then
    echo "Command timed out - removing trace ${OUTPUT_PATH}"
    rm "${OUTPUT_PATH}"
fi
