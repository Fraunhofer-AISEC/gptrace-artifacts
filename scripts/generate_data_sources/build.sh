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

# Get crashing inputs that were used in the evaluation

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${0}")/.." && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"
GEN_DATA_SRCS_DIR="${REPRODUCE_DIR}/generate_data_sources"

TARGET="${1}"

echo ""
echo "##########################################"
echo "Building docker image for target ${TARGET}"
echo "##########################################"
echo ""

TARGETLIB="$(echo ${TARGET} | awk -F '__' '{print $1}')"
PROGRAM="$(echo ${TARGET} | awk -F '__' '{print $2}')"

BASETAG="gptrace/${TARGET}/base"
FINALTAG="gptrace/${TARGET}"
NO_ASAN="FALSE"

if [ "$#" -gt 1 ]; then
    BASETAG="default/${TARGET}/base"
    FINALTAG="default/${TARGET}"
    NO_ASAN="TRUE"
fi

case "${TARGET}" in
freetype__char2svg | libtiff__tiff2pdf | libxml2__xmllint | poppler__pdftotext | soxmp3__sox | soxwav__sox)
    BASEIMG=ubuntu:22.04
    DOCKERFILE="Dockerfile.MoonLight"
    ;;
libtiff__tiffcp | libxml2__libxml2_xml_read_memory_fuzzer | openssl__client | openssl__x509 | php__exif | poppler__pdf_fuzzer | poppler__pdfimages | poppler__pdftoppm)
    FUZZER=aflplusplus_asan
    case "${NO_ASAN}" in
    TRUE)
        FUZZER=aflplusplus
        ;;
    esac

    BASEIMG=magma/${FUZZER}/${TARGETLIB}
    DOCKERFILE="Dockerfile.Magma"

    echo "Building magma parent image for ${TARGETLIB} with fuzzer ${FUZZER}"
    FUZZER=${FUZZER} TARGET=${TARGETLIB} ${GEN_DATA_SRCS_DIR}/magma/tools/captain/build.sh
    ;;
*)
    echo "Invalid target: ${TARGET}" >&2
    exit
    ;;
esac

TARGETPATH="${GEN_DATA_SRCS_DIR}/targets/${TARGET}"

NO_CACHE=""

# Uncomment the following line to build the Docker images without cache
# NO_CACHE="TRUE"

cleanup() {
    [ -f "${TARGETPATH}/Dockerfile.Common" ] && rm "${TARGETPATH}/Dockerfile.Common"
    [ -f "${TARGETPATH}/${DOCKERFILE}" ] && rm "${TARGETPATH}/${DOCKERFILE}"
    [ -f "${TARGETPATH}/run.sh" ] && rm "${TARGETPATH}/run.sh"
    [ -f "${TARGETPATH}/run_pin.sh" ] && rm "${TARGETPATH}/run_pin.sh"
    [ -f "${TARGETPATH}/run_default.sh" ] && rm "${TARGETPATH}/run_default.sh"
    [ -f "${TARGETPATH}/run_crashwalk.sh" ] && rm "${TARGETPATH}/run_crashwalk.sh"
    [ -f "${TARGETPATH}/run_crashwalk_provided.sh" ] && rm "${TARGETPATH}/run_crashwalk_provided.sh"
    [ -f "${TARGETPATH}/rename.py" ] && rm "${TARGETPATH}/rename.py"
    [ -f "${TARGETPATH}/.dockerignore" ] && rm "${TARGETPATH}/.dockerignore"
    [ -f "${TARGETPATH}/crashwalk_gta.py" ] && rm "${TARGETPATH}/crashwalk_gta.py"
    [ -d "${TARGETPATH}/gptrace" ] && rm -r "${TARGETPATH}/gptrace"
    [ -d "${TARGETPATH}/default" ] && rm -r "${TARGETPATH}/default"
}

trap cleanup EXIT

echo "Building common base image based on ${BASEIMG}"

cp "${GEN_DATA_SRCS_DIR}/docker/.dockerignore" "${TARGETPATH}/.dockerignore"
cp "${GEN_DATA_SRCS_DIR}/docker/Dockerfile.Common" "${TARGETPATH}/Dockerfile.Common"
cp "${GEN_DATA_SRCS_DIR}/docker/run.sh" "${TARGETPATH}/run.sh"
cp "${GEN_DATA_SRCS_DIR}/docker/run_pin.sh" "${TARGETPATH}/run_pin.sh"
cp "${GEN_DATA_SRCS_DIR}/docker/run_default.sh" "${TARGETPATH}/run_default.sh"
cp "${GEN_DATA_SRCS_DIR}/docker/run_crashwalk.sh" "${TARGETPATH}/run_crashwalk.sh"
cp "${GEN_DATA_SRCS_DIR}/docker/run_crashwalk_provided.sh" "${TARGETPATH}/run_crashwalk_provided.sh"
cp "${GEN_DATA_SRCS_DIR}/docker/crashwalk_gta.py" "${TARGETPATH}/crashwalk_gta.py"
cp "${GEN_DATA_SRCS_DIR}/docker/rename.py" "${TARGETPATH}/rename.py"
rsync -a "${PROJECT_ROOT}/gptrace" "${TARGETPATH}" \
    --exclude .venv --exclude .git --exclude .gitignore
rsync -a "${PROJECT_ROOT}/default" "${TARGETPATH}" \
    --exclude .venv --exclude .git --exclude .gitignore \
    --exclude example_data.tar.gz --exclude example_data

if [ -n "${NO_CACHE}" ]; then
    docker build -t "${BASETAG}" --no-cache \
        --build-arg BASEIMG=${BASEIMG} -f ${TARGETPATH}/Dockerfile.Common \
        ${TARGETPATH} || exit 1
else
    docker build -t "${BASETAG}" \
        --build-arg BASEIMG=${BASEIMG} -f ${TARGETPATH}/Dockerfile.Common \
        ${TARGETPATH} || exit 1
fi

echo "Building target image based on ${BASETAG}"
cp "${GEN_DATA_SRCS_DIR}/docker/${DOCKERFILE}" "${TARGETPATH}/${DOCKERFILE}"

if [ -f ${TARGETPATH}/Dockerfile_addition ]; then
    cat ${TARGETPATH}/Dockerfile_addition >>${TARGETPATH}/${DOCKERFILE}
fi
if [ -n "${NO_CACHE}" ]; then
    docker build -t "${FINALTAG}" --no-cache \
        --build-arg USER_ID=$(id -u $USER) \
        --build-arg GROUP_ID=$(id -g $USER) \
        --build-arg BASEIMG="${BASETAG}" \
        --build-arg PROGRAM="${PROGRAM}" -f "${TARGETPATH}/${DOCKERFILE}" \
        "${TARGETPATH}" || exit 1
else
    docker build -t "${FINALTAG}" \
        --build-arg USER_ID=$(id -u $USER) \
        --build-arg GROUP_ID=$(id -g $USER) \
        --build-arg BASEIMG="${BASETAG}" \
        --build-arg PROGRAM="${PROGRAM}" -f "${TARGETPATH}/${DOCKERFILE}" \
        "${TARGETPATH}" || exit 1
fi
