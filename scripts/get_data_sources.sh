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

# Get data sources from Zenodo

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${0}")" && pwd)
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")
REPRODUCE_DIR="${PROJECT_ROOT}/reproduce"

EVAL_DIR="${REPRODUCE_DIR}/evaluation"
mkdir -p "${EVAL_DIR}"

ZENODO_BASE_URL="https://zenodo.org/records/18708473/files"

echo "Downloading archives from Zenodo"
wget -O "${EVAL_DIR}/cache.tar.gz" "${ZENODO_BASE_URL}/cache.tar.gz"
wget -O "${EVAL_DIR}/data_sources.tar.gz" "${ZENODO_BASE_URL}/data_sources.tar.gz"

echo "Extracting archives"
tar xzf "${EVAL_DIR}/cache.tar.gz" -C "${EVAL_DIR}"
tar xzf "${EVAL_DIR}/data_sources.tar.gz" -C "${EVAL_DIR}"
