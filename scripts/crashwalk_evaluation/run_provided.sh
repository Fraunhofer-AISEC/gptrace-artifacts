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

# Evaluate Crashwalk with provided data sources

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${0}")/.." && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"
EVAL_DIR="${REPRODUCE_DIR}/evaluation"

TARGET="${1}"

echo ""
echo "#########################################"
echo "Evaluating Crashwalk for target ${TARGET}"
echo "#########################################"
echo ""

case "${TARGET}" in
freetype__char2svg | libtiff__tiff2pdf | libxml2__xmllint | poppler__pdftotext | soxmp3__sox | soxwav__sox | libtiff__tiffcp | libxml2__libxml2_xml_read_memory_fuzzer | openssl__client | openssl__x509 | php__exif | poppler__pdf_fuzzer | poppler__pdfimages | poppler__pdftoppm)
    CONTAINER_NAME="crashwalk_provided-${TARGET}"
    DATA_SOURCES_DIR="${EVAL_DIR}/data_sources/${TARGET}/crashwalk"
    RESULTS_DIR="${EVAL_DIR}/results/crashwalk/${TARGET}"
    mkdir -p "${RESULTS_DIR}"

    docker run -dt --name "${CONTAINER_NAME}" \
        --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
        -v "${DATA_SOURCES_DIR}":/project/out \
        -v "${RESULTS_DIR}":/project/results \
        gptrace/${TARGET}

    docker exec -d ${CONTAINER_NAME} /project/run_crashwalk_provided.sh
    ;;
*)
    echo "Invalid target: ${TARGET}" >&2
    exit 1
    ;;
esac
