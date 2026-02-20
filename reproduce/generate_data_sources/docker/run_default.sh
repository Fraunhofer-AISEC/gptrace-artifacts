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

source /project/default/.venv/bin/activate
source /project/env_variables.sh
PROG_TIMEOUT="${PROG_TIMEOUT:-120}"
PROG_WORKERS="${PROG_WORKERS:-128}"

ACTUAL_WORKERS="${1:-${PROG_WORKERS}}"
ACTUAL_TIMEOUT="${2:-${PROG_TIMEOUT}}"

mkdir -p /project/out/default
LOGFILE=/project/out/default/pin.log

python3 rename.py --rename_inputs --default

INPUTFILE=/project/default/input_list

process_inputs() {
    INPUT_PATH="${1}"
    OUTPUT_PATH="${2}"

    [ -f "${INPUTFILE}" ] && rm "${INPUTFILE}"

    for INPUT in $(ls "${INPUT_PATH}"); do
        OUTFILE="${OUTPUT_PATH}/${INPUT}"
        if [ -s ${OUTFILE} ]; then
            echo "Trace ${OUTFILE} already exists" >>"${LOGFILE}"
        else
            echo "Processing ${INPUT_PATH}/${INPUT}" >>"${LOGFILE}"
            echo "${INPUT_PATH}/${INPUT} ${OUTFILE}" >>"${INPUTFILE}"
        fi
    done

    [ -f "${INPUTFILE}" ] && parallel -j ${ACTUAL_WORKERS} --colsep ' ' /project/run_pin.sh {1} {2} ${ACTUAL_TIMEOUT} :::: "${INPUTFILE}" >>"${LOGFILE}"

    [ -f "${INPUTFILE}" ] && rm "${INPUTFILE}"
}

echo "Processing inputs" >>"${LOGFILE}"
mkdir -p /project/clean_pin_traces
process_inputs /project/clean_inputs /project/clean_pin_traces

echo "Processed all inputs" >>"${LOGFILE}"

python3 rename.py --default

echo "Running DeFault now (this might take some time)" >>"${LOGFILE}"

cd /project/default

uv run default -c /project/out/default/pin_traces/crashing -n /project/out/default/pin_traces/non_crashing -o /project/out/default >>"${LOGFILE}"
