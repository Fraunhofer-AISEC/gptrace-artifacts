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

# Evaluate GPTrace with own data sources

set -euo pipefail

IGNORE_WARNINGS=""

# Uncomment the following line to ignore deprecation warnings from sklearn
IGNORE_WARNINGS="TRUE"

SCRIPT_DIR=$(cd "$(dirname "${0}")/.." && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"
GEN_DIR="${REPRODUCE_DIR}/generate_data_sources"

TARGET="${1}"

echo ""
echo "#######################################"
echo "Evaluating GPTrace for target ${TARGET}"
echo "#######################################"
echo ""

evaluate() {
    TARGET="${1}"
    case "${TARGET}" in
    freetype__char2svg | libtiff__tiff2pdf | libxml2__xmllint | poppler__pdftotext | soxmp3__sox | soxwav__sox | libtiff__tiffcp | libxml2__libxml2_xml_read_memory_fuzzer | openssl__client | openssl__x509 | php__exif | poppler__pdf_fuzzer | poppler__pdfimages | poppler__pdftoppm)
        TARGET_DIR="${GEN_DIR}/targets/${TARGET}"
        OUTPATH="${TARGET_DIR}/out"
        ASAN_DIR="${OUTPATH}/asan_logs"
        TRACES_DIR="${OUTPATH}/traces"
        CACHE_DIR="${OUTPATH}/cache/text-embedding-3-large"
        RAW_RESULTS_DIR="${OUTPATH}/raw_gptrace_results"

        mkdir -p "${RAW_RESULTS_DIR}"
        mkdir -p "${CACHE_DIR}"

        pushd "${PROJECT_ROOT}/gptrace"

        source "${PROJECT_ROOT}/gptrace/.venv/bin/activate"
        uv run gptrace --openai -d 64 -g -r -l "${OUTPATH}/gptrace.log" -o "${RAW_RESULTS_DIR}" -c "${CACHE_DIR}" -a "${ASAN_DIR}" "${TRACES_DIR}"

        popd
        ;;
    *)
        echo "Invalid target: ${TARGET}" >&2
        exit 1
        ;;
    esac
}

if [ -n "${IGNORE_WARNINGS}" ]; then
    evaluate "${TARGET}" 2> >(grep -v "was renamed to" | grep -v "warnings.warn(" >&2)
else
    evaluate "${TARGET}"
fi
