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

GEN_DIR="${REPRODUCE_DIR}/generate_data_sources"

git clone https://github.com/HexHive/PoCalypse.git "${GEN_DIR}/PoCalypse"
git -C "${GEN_DIR}/PoCalypse" checkout 9f1cc457562c9bb4421475e16cb8f5b851739058
git -C "${GEN_DIR}/PoCalypse" apply "${GEN_DIR}/modified_structure.patch"

ZENODO_BASE_URL="https://zenodo.org/records/18708473/files"

# Get archive of non-crashing inputs from Zenodo and extract it
wget -O "${GEN_DIR}/non_crashing_inputs.tar.gz" "${ZENODO_BASE_URL}/non_crashing_inputs.tar.gz"

tar xzf "${GEN_DIR}/non_crashing_inputs.tar.gz" -C "${GEN_DIR}"

TARGETS="freetype__char2svg libtiff__tiff2pdf libtiff__tiffcp libxml2__libxml2_xml_read_memory_fuzzer libxml2__xmllint openssl__client openssl__x509 php__exif poppler__pdf_fuzzer poppler__pdfimages poppler__pdftoppm poppler__pdftotext soxmp3__sox soxwav__sox"

# Organize inputs into target directories
for TARGET in ${TARGETS}; do
    mv "${GEN_DIR}/PoCalypse/${TARGET}" "${GEN_DIR}/targets/${TARGET}/inputs"
    mv "${GEN_DIR}/non_crashing_inputs/${TARGET}" "${GEN_DIR}/targets/${TARGET}/non_crashing_inputs"
done

rm -rf "${GEN_DIR}/PoCalypse"
rmdir "${GEN_DIR}/non_crashing_inputs"
