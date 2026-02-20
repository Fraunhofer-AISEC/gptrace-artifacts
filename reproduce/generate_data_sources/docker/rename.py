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

"""Rename input files so that no information can be gathered from filenames"""

from pathlib import Path
import shutil
import pickle
import argparse


def rename_general(rename_inputs: bool):
    input_path = Path("/project/inputs")
    clean_input_path = Path("/project/clean_inputs")
    translation_path = Path("/project/translation")
    clean_traces_path = Path("/project/clean_traces")
    traces_path = Path("/project/out/traces")
    asan_path = Path("/project/out/asan_logs")

    if rename_inputs:
        files = input_path.glob("**/*")
        clean_input_path.mkdir(parents=True, exist_ok=True)
        translation = {}

        i = 0
        for f in files:
            if not f.is_file():
                continue

            goal = clean_input_path / f"input_{i}{f.suffix}"
            shutil.copyfile(f, goal)
            translation[f] = goal
            i += 1

        with open(translation_path, "wb") as t:
            pickle.dump(translation, t)
    else:
        with open(translation_path, "rb") as t:
            translation = pickle.load(t)

        for f, i in translation.items():
            trace_filename = i.name
            trace = clean_traces_path / f"{trace_filename}_trace"

            if not trace.is_file():
                continue

            goal_filename = f.name
            goal_sci_name = f.parent.name

            goal = traces_path / goal_sci_name / goal_filename
            (goal.parent).mkdir(parents=True, exist_ok=True)
            shutil.move(trace, goal)

            asan_log_list = list(clean_traces_path.glob(f"{trace_filename}_asan.*"))
            if not len(asan_log_list) == 1:
                continue
            else:
                asan_log = asan_log_list[0]
                goal = asan_path / goal_sci_name / goal_filename
                (goal.parent).mkdir(parents=True, exist_ok=True)
                shutil.move(asan_log, goal)


def rename_default(rename_inputs: bool):
    input_path = Path("/project/inputs")
    non_crashing_input_path = Path("/project/non_crashing_inputs")
    clean_input_path = Path("/project/clean_inputs")
    translation_path = Path("/project/translation_default")
    clean_traces_path = Path("/project/clean_pin_traces")
    traces_path = Path("/project/out/default/pin_traces/crashing")
    non_crashing_traces_path = Path("/project/out/default/pin_traces/non_crashing")

    if rename_inputs:
        clean_input_path.mkdir(parents=True, exist_ok=True)
        translation = {}

        files = input_path.glob("**/*")
        i = 0
        for f in files:
            if not f.is_file():
                continue

            goal = clean_input_path / f"input_{i}{f.suffix}"
            shutil.copyfile(f, goal)
            translation[f] = goal
            i += 1

        files = non_crashing_input_path.glob("**/*")
        for f in files:
            if not f.is_file():
                continue

            goal = clean_input_path / f"input_{i}{f.suffix}"
            shutil.copyfile(f, goal)
            translation[f] = goal
            i += 1

        with open(translation_path, "wb") as t:
            pickle.dump(translation, t)
    else:
        with open(translation_path, "rb") as t:
            translation = pickle.load(t)

        for f, i in translation.items():
            trace_filename = i.name
            trace = clean_traces_path / f"{trace_filename}"

            if not trace.is_file():
                continue

            goal_filename = f.name
            goal_sci_name = f.parent.name

            if "non_crashing_inputs" in goal_sci_name:
                goal = non_crashing_traces_path / goal_filename
            else:
                goal = traces_path / goal_sci_name / goal_filename

            (goal.parent).mkdir(parents=True, exist_ok=True)
            shutil.move(trace, goal)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rename_inputs", action="store_true")
    parser.add_argument("--default", action="store_true")
    args = parser.parse_args()

    if args.default:
        rename_default(args.rename_inputs)
    else:
        rename_general(args.rename_inputs)

if __name__ == "__main__":
    main()
