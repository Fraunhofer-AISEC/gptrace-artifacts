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

# Evaluate Crashwalk with own data sources

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${0}")/.." && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"
GEN_DIR="${REPRODUCE_DIR}/generate_data_sources"

TARGET="${1}"
DEF_WORKERS=$(($(nproc --all) / 4))
PROG_WORKERS="${2:-${DEF_WORKERS}}"
DEF_TIMEOUT=120
PROG_TIMEOUT="${3:-${DEF_TIMEOUT}}"

echo ""
echo "#########################################"
echo "Evaluating Crashwalk for target ${TARGET}"
echo "#########################################"
echo ""

case "${TARGET}" in
freetype__char2svg | libtiff__tiff2pdf | libxml2__xmllint | poppler__pdftotext | soxmp3__sox | soxwav__sox | libtiff__tiffcp | libxml2__libxml2_xml_read_memory_fuzzer | openssl__client | openssl__x509 | php__exif | poppler__pdf_fuzzer | poppler__pdfimages | poppler__pdftoppm)
    CONTAINER_NAME="crashwalk-${TARGET}"
    TARGET_DIR="${GEN_DIR}/targets/${TARGET}"
    mkdir -p "${TARGET_DIR}/out"

    docker run -dt --name "${CONTAINER_NAME}" \
        --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
        -v "${TARGET_DIR}/out":/project/out \
        -v "${TARGET_DIR}/inputs":/project/inputs \
        gptrace/${TARGET}

    docker exec -d ${CONTAINER_NAME} /project/run_crashwalk.sh ${PROG_WORKERS} ${PROG_TIMEOUT}
    ;;
*)
    echo "Invalid target: ${TARGET}" >&2
    exit 1
    ;;
esac
