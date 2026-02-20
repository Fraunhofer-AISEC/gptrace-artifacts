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

# Reproduce evaluation using provided data sources and cache

set -euo pipefail

IGNORE_WARNINGS=""

# Uncomment the following line to ignore deprecation warnings from sklearn
IGNORE_WARNINGS="TRUE"

SCRIPT_DIR=$(cd "$(dirname "${0}")" && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"
EVAL_DIR="${REPRODUCE_DIR}/evaluation"
RESULTS_DIR="${EVAL_DIR}/results"

pushd "${PROJECT_ROOT}/gptrace"

evaluate() {
    TARGET="${1}"

    ASAN_DIR="${EVAL_DIR}/data_sources/${TARGET}/asan_logs"
    TRACES_DIR="${EVAL_DIR}/data_sources/${TARGET}/traces"
    CACHE_DIR="${EVAL_DIR}/cache/text-embedding-3-large/${TARGET}"

    echo ""
    echo "###################################################"
    echo "Reproducing GPTrace evaluation for target ${TARGET}"
    echo "###################################################"
    echo ""

    echo "### Results of GPTrace"

    echo "Default GPTrace configuration"
    OUTPATH="${RESULTS_DIR}/gptrace_default/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"

    echo "### Effect of Choice of Data Sources"

    echo "Only ASan reports"
    OUTPATH="${RESULTS_DIR}/asan_only/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r --asan_only --keep_asan_traces -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"

    echo "No ASan reports"
    OUTPATH="${RESULTS_DIR}/no_asan/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" "${TRACES_DIR}"

    echo "No full traces"
    OUTPATH="${RESULTS_DIR}/no_full/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r --remove_arguments --no_separate_remove_arguments -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"

    echo "No coarse traces"
    OUTPATH="${RESULTS_DIR}/no_coarse/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r --no_separate_remove_arguments -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"

    echo "Only full traces"
    OUTPATH="${RESULTS_DIR}/full_traces_only/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r --no_separate_remove_arguments -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" "${TRACES_DIR}"

    echo "Only coarse traces"
    OUTPATH="${RESULTS_DIR}/coarse_traces_only/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --openai --no_llm -d 64 -g -r --remove_arguments --no_separate_remove_arguments -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" "${TRACES_DIR}"

    echo "### Effect of Choice of Embedding Model"

    echo "NV-Embed-v2"
    CACHE_DIR="${EVAL_DIR}/cache/nv-embed/${TARGET}"
    OUTPATH="${RESULTS_DIR}/nv-embed/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --huggingface nvidia_nv_embed_v2 --no_llm -d 64 -g -r -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"

    echo "stella_en_1.5B_v5"
    CACHE_DIR="${EVAL_DIR}/cache/stella/${TARGET}"
    OUTPATH="${RESULTS_DIR}/stella/${TARGET}"
    mkdir -p "${OUTPATH}"
    uv run gptrace --huggingface dunzhang_stella_en_1_5b_v5 --no_llm -d 64 -g -r -l "${OUTPATH}/log" -o "${OUTPATH}/raw_results" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"
}

TARGETS="freetype__char2svg openssl__client php__exif libxml2__libxml2_xml_read_memory_fuzzer poppler__pdf_fuzzer poppler__pdfimages poppler__pdftoppm poppler__pdftotext soxmp3__sox soxwav__sox libtiff__tiff2pdf libtiff__tiffcp openssl__x509 libxml2__xmllint"

for T in $(echo ${TARGETS} | tr ' ' '\n'); do
    if [ -n "${IGNORE_WARNINGS}" ]; then
        evaluate "${T}" 2> >(grep -v "was renamed to" | grep -v "warnings.warn(" >&2)
    else
        evaluate "${T}"
    fi
done

popd
