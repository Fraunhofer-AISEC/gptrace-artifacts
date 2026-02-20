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

# Build all docker images

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${0}")" && pwd)

WHAT="${1}"
TARGETS="${2:-all}"

GEN_DIR="${SCRIPT_DIR}/generate_data_sources"

# If desired, set the number of workers here
# OVERWRITE_WORKERS=128

EXTRA_ARG=""
DEF_WORKERS=$(($(nproc --all) / 16))

case "${WHAT}" in
build)
    echo "Building Docker images"
    SCRIPT_PATH="${GEN_DIR}/build.sh"
    ;;
build-default)
    echo "Building Docker images for DeFault"
    SCRIPT_PATH="${GEN_DIR}/build.sh"
    EXTRA_ARG="TRUE"
    ;;
collect)
    echo "Collecting data sources"
    SCRIPT_PATH="${GEN_DIR}/run.sh"
    EXTRA_ARG="${OVERWRITE_WORKERS:-${DEF_WORKERS}}"
    ;;
crashwalk)
    echo "Evaluating Crashwalk with own data sources"
    SCRIPT_PATH="${SCRIPT_DIR}/crashwalk_evaluation/run.sh"
    EXTRA_ARG="${OVERWRITE_WORKERS:-${DEF_WORKERS}}"
    ;;
crashwalk_provided)
    echo "Evaluating Crashwalk with provided data sources"
    SCRIPT_PATH="${SCRIPT_DIR}/crashwalk_evaluation/run_provided.sh"
    ;;
default)
    echo "Evaluating DeFault with own data sources"
    SCRIPT_PATH="${SCRIPT_DIR}/default_evaluation/run.sh"
    EXTRA_ARG="${OVERWRITE_WORKERS:-${DEF_WORKERS}}"
    ;;
gptrace)
    echo "Evaluating GPTrace with own data sources"
    SCRIPT_PATH="${SCRIPT_DIR}/gptrace_evaluation/run.sh"
    ;;
*)
    echo "Invalid script argument: ${WHAT}" >&2
    exit 1
    ;;
esac

MOONLIGHT="freetype__char2svg libtiff__tiff2pdf libxml2__xmllint poppler__pdftotext soxmp3__sox soxwav__sox"
MAGMA="libtiff__tiffcp libxml2__libxml2_xml_read_memory_fuzzer openssl__client openssl__x509 php__exif poppler__pdf_fuzzer poppler__pdfimages poppler__pdftoppm"

case "${TARGETS}" in
all)
    echo "Using all targets"
    BUILD="$MOONLIGHT $MAGMA"
    ;;
moonlight)
    echo "Using all moonlight targets"
    BUILD="$MOONLIGHT"
    ;;
magma)
    echo "Using all magma targets"
    BUILD="$MAGMA"
    ;;
*)
    echo "Invalid target argument: ${TARGETS}" >&2
    exit 1
    ;;
esac

for TARGET in $(echo ${BUILD} | tr ' ' '\n' | sort); do
    FAILED=""
    ${SCRIPT_PATH} ${TARGET} ${EXTRA_ARG} || FAILED="TRUE"

    if [ -n "${FAILED}" ]; then
        echo "Failed to run ${SCRIPT_PATH} ${TARGET}" >&2
        exit 1
    fi
done
