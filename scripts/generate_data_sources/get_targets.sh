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

# Get Magma and MoonLight targets for data generation

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${0}")/.." && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"

GEN_DIR="${REPRODUCE_DIR}/generate_data_sources"

# Get MoonLight targets
function get_moonlight_target {
    local TARGET_NAME="${1}"
    local MOONLIGHT_NAME="${2}"
    local BINARY_NAME="${3}"

    local TARGET_DIR="${GEN_DIR}/targets/${TARGET_NAME}"
    local MOONLIGHT_BASE_URL="https://datacommons.anu.edu.au/DataCommons/rest/records/anudc:5927/data/Binaries"

    mkdir -p "${TARGET_DIR}"

    # Get binary archive
    wget -O "${TARGET_DIR}/binary.tar.gz" \
        "${MOONLIGHT_BASE_URL}/${MOONLIGHT_NAME}_llvm_asan.tar.gz"

    # Extract binary archive
    tar xzf "${TARGET_DIR}/binary.tar.gz" -C "${TARGET_DIR}"
    mv "${TARGET_DIR}/${MOONLIGHT_NAME}_llvm_asan" "${TARGET_DIR}/binary"
}

echo "Downloading MoonLight targets"
get_moonlight_target "freetype__char2svg" "ttf253" "char2svg"
get_moonlight_target "libtiff__tiff2pdf" "tiff409c710" "tiff2pdf"
get_moonlight_target "libxml2__xmllint" "xml290" "xmllint"
get_moonlight_target "poppler__pdftotext" "pdf" "pdftotext"
get_moonlight_target "soxmp3__sox" "sox" "sox"
get_moonlight_target "soxwav__sox" "sox" "sox"

echo "Cloning Magma repository"
git clone --branch v1.2.1 https://github.com/HexHive/magma.git "${GEN_DIR}/magma"
git -C "${GEN_DIR}/magma" apply "${GEN_DIR}/aflplusplus_asan.patch"

echo -e "\n\nMake sure the Magma dependencies are installed \
(see https://hexhive.epfl.ch/magma/docs/getting-started.html) \
before continuing with the subsequent steps."
