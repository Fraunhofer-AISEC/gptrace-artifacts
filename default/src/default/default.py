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

"""Rudimentary implementation of DeFault.

Based on the following paper:
Xing Zhang, Jiongyi Chen, Chao Feng, Ruilin Li, Wenrui Diao, Kehuan Zhang,
Jing Lei, and Chaojing Tang. 2022.
DeFault: mutual information-based crash triage for massive crashes.
In Proceedings of the 44th International Conference on Software Engineering
(ICSE '22). Association for Computing Machinery, New York, NY, USA, 635–646.
<https://doi.org/10.1145/3510003.3512760>
"""

import argparse
import logging
import sys
from collections import defaultdict
from math import log2
from pathlib import Path

from tqdm import tqdm

from default.ground_truth_analysis import analyze_clustering_performance


def entropy(Nf: int, Np: int) -> float:
    """Calculate the entropy of the crashing behavior."""
    if Nf == 0 or Np == 0:
        return 0
    N = Nf + Np

    p_f = Nf / N
    p_p = Np / N
    return -(p_f * log2(p_f) + p_p * log2(p_p))


def compute_dicts(
    unique_b: set[str], Bf: list[dict[str, int]], Bp: list[dict[str, int]]
) -> tuple[
    dict[str, defaultdict[int, int]],
    dict[str, defaultdict[int, int]],
    dict[str, defaultdict[int, int]],
]:
    """Compute the occurrence dictionaries for basic blocks."""
    logging.info(f"Computing occurrence dictionaries for {len(unique_b)} basic blocks")

    ci_dict: dict[str, defaultdict[int, int]] = {}
    cfi_dict: dict[str, defaultdict[int, int]] = {}
    cpi_dict: dict[str, defaultdict[int, int]] = {}
    for b in unique_b:
        ci_dict[b] = defaultdict(int)
        cfi_dict[b] = defaultdict(int)
        cpi_dict[b] = defaultdict(int)

    for trace in tqdm(Bf):
        for b in unique_b:
            num = trace.get(b, 0)
            ci_dict[b][num] += 1
            cfi_dict[b][num] += 1

    for trace in tqdm(Bp):
        for b in unique_b:
            num = trace.get(b, 0)
            ci_dict[b][num] += 1
            cpi_dict[b][num] += 1

    logging.info("Finished computing occurrence dictionaries for basic blocks")
    return ci_dict, cfi_dict, cpi_dict


def csum(b: str, lower: int, upper: int, c: dict[str, defaultdict[int, int]]) -> int:
    """Compute the number of traces that contain basic block b i times."""
    res = 0
    for key in c[b].keys():
        if lower <= key <= upper:
            res += c[b][key]
    return res


def maxnb(b: str, D: list[dict[str, int]]) -> int:
    """Compute the maximum number of occurrences of basic block b in traces."""
    return max(trace.get(b, 0) for trace in D)


def mutual_info(
    b: str,
    Bf: list[dict[str, int]],
    Bp: list[dict[str, int]],
    Hy: float,
    ci: dict[str, defaultdict[int, int]],
    cfi: dict[str, defaultdict[int, int]],
    cpi: dict[str, defaultdict[int, int]],
    m: int,
) -> float:
    """Compute the mutual information of basic block b."""
    Hyb: float = 0
    Nf = len(Bf)
    Np = len(Bp)
    N = Nf + Np

    for i in range(0, m + 1):
        ci_current = ci[b].get(i, 0)
        if ci_current == 0:
            continue

        cfi_current = cfi[b].get(i, 0) / ci_current
        cpi_current = cpi[b].get(i, 0) / ci_current

        # ci_current is cancelled out
        cfi_factor = cfi[b].get(i, 0) * log2(cfi_current) if cfi_current > 0 else 0
        cpi_factor = cpi[b].get(i, 0) * log2(cpi_current) if cpi_current > 0 else 0

        Hyb += (cpi_factor + cfi_factor) / N

    mi = Hy + Hyb

    return mi


def cond_entropy_below(
    b: str,
    N: int,
    thd: int,
    ci: dict[str, defaultdict[int, int]],
    cfi: dict[str, defaultdict[int, int]],
    cpi: dict[str, defaultdict[int, int]],
) -> float:
    """Compute the conditional entropy of basic block below a threshold."""
    sum_ci = csum(b, 0, thd, ci)

    if sum_ci == 0:
        return 0

    sum_cfi = csum(b, 0, thd, cfi)
    sum_cpi = csum(b, 0, thd, cpi)

    quot_fi = sum_cfi / sum_ci
    quot_pi = sum_cpi / sum_ci

    # sum_ci is cancelled out
    factor_fi = sum_cfi * log2(quot_fi) if sum_cfi > 0 else 0
    factor_pi = sum_cpi * log2(quot_pi) if sum_cpi > 0 else 0

    result = (-factor_pi - factor_fi) / N

    return result


def cond_entropy_above(
    b: str,
    N,
    thd: int,
    ci: dict[str, defaultdict[int, int]],
    cfi: dict[str, defaultdict[int, int]],
    cpi: dict[str, defaultdict[int, int]],
    m: int,
) -> float:
    """Compute the conditional entropy of basic block above a threshold."""
    # In the paper, the expression is
    # sum_ci = csum_ci(b, 0, thd, ci)
    # but this does not make sense
    # (cf. https://en.wikipedia.org/wiki/Conditional_entropy)
    # Instead it needs to be the following
    sum_ci = csum(b, thd + 1, m, ci)

    if sum_ci == 0:
        return 0

    sum_cfi = csum(b, thd + 1, m, cfi)
    sum_cpi = csum(b, thd + 1, m, cpi)

    quot_fi = sum_cfi / sum_ci
    quot_pi = sum_cpi / sum_ci

    # sum_ci is cancelled out
    factor_fi = sum_cfi * log2(quot_fi) if sum_cfi > 0 else 0
    factor_pi = sum_cpi * log2(quot_pi) if sum_cpi > 0 else 0

    result = (-factor_pi - factor_fi) / N

    return result


def mutual_info_thd(
    b: str,
    N: int,
    Hy: float,
    thd: int,
    ci: dict[str, defaultdict[int, int]],
    cfi: dict[str, defaultdict[int, int]],
    cpi: dict[str, defaultdict[int, int]],
    m: int,
) -> float:
    """Compute the mutual information with thd of basic block b."""
    below = cond_entropy_below(b, N, thd, ci, cfi, cpi)
    above = cond_entropy_above(b, N, thd, ci, cfi, cpi, m)

    return Hy - below - above


def thd_hat(
    b: str,
    N: int,
    Hy: float,
    ci: dict[str, defaultdict[int, int]],
    cfi: dict[str, defaultdict[int, int]],
    cpi: dict[str, defaultdict[int, int]],
    m: int,
) -> int:
    """Find the threshold that maximizes the mutual information of basic block b."""
    max_mi = float("-inf")
    best_thd = 0

    for thd in ci[b].keys():
        if thd < 0 or m <= thd:
            continue
        mi = mutual_info_thd(b, N, Hy, thd, ci, cfi, cpi, m)
        if mi > max_mi:
            max_mi = mi
            best_thd = thd

    return best_thd


def is_crashing(
    b: str,
    Nf: int,
    Np: int,
    thd: int,
    cfi: dict[str, defaultdict[int, int]],
    cpi: dict[str, defaultdict[int, int]],
    m: int,
) -> bool:
    """Consider block based on a threshold."""
    sum_cfi = csum(b, thd + 1, m, cfi) / Nf
    sum_cpi = csum(b, thd + 1, m, cpi) / Np

    if sum_cpi > sum_cfi:
        return False
    else:
        return True


def deduplication(
    Bf_dict: dict[Path, dict[str, int]], Bp_dict: dict[Path, dict[str, int]]
) -> list[list[Path]]:
    """Deduplicate crashing and non-crashing traces."""
    groups: list[list[Path]] = []
    prev_len = float("inf")
    while len(Bf_dict) > 0 and len(Bp_dict) > 0:
        Bf = list(Bf_dict.values())
        Bp = list(Bp_dict.values())

        Nf = len(Bf)
        Np = len(Bp)
        N = Nf + Np
        logging.info(
            f"Number of crashing traces: {Nf}, Number of non-crashing traces: {Np}"
        )

        if prev_len <= Nf:
            trace_list: list[Path] = list(Bf_dict.keys())
            groups.append(trace_list)
            logging.warning("No more progress can be made")
            logging.warning("Adding remaining traces as one group")
            logging.debug(f"Traces are: {trace_list}")
            return groups

        prev_len = Nf

        D = Bf + Bp
        unique_b = {b for trace in D for b in trace.keys()}
        ci, cfi, cpi = compute_dicts(unique_b, Bf, Bp)

        Hy = entropy(Nf, Np)

        b_mi_dict: dict[str, tuple[float, int]] = {}
        best_b = None
        best_mi = float("-inf")
        best_thd = 0
        logging.info("Collecting basic blocks from traces")
        handled_b = set()
        for trace in tqdm(D):
            for b in trace:
                if b in handled_b:
                    continue
                else:
                    m = maxnb(b, D)
                    mi = mutual_info(b, Bf, Bp, Hy, ci, cfi, cpi, m)
                    if mi > best_mi:
                        b_mi_dict[b] = (mi, m)
                    handled_b.add(b)

        logging.info(
            f"Looking for basic block with largest mutual information among "
            f"{len(b_mi_dict)} candidates"
        )

        for b, (mi, m) in sorted(
            b_mi_dict.items(), key=lambda kv: kv[1][0], reverse=True
        ):
            thd = thd_hat(b, N, Hy, ci, cfi, cpi, m)
            if is_crashing(b, Nf, Np, thd, cfi, cpi, m):
                best_mi = mi
                best_b = b
                best_thd = thd
                break
            else:
                logging.debug(
                    f"Basic block {b} with mutual information {mi} threshold "
                    f"{thd} is not crashing, skipping"
                )

                continue

        if best_b is None:
            logging.warning("No non-filtered basic found.")
            continue

        logging.info(
            f"Best basic block: {best_b} with mutual information {best_mi} and "
            f"threshold {best_thd}"
        )

        # The starting index is missing in the paper (it has to be 0)
        sum_cfi = csum(best_b, 0, best_thd, cfi)

        # This if block is not really necessary since new_Bf_dict will contain
        # all traces if sum_cfi is 0 and so the while loop will be terminated
        # but we leave it here for clarity
        if sum_cfi == 0:
            logging.info(f"Basic block {best_b} is present in all crashing traces.")
            groups.append(list(Bf_dict.keys()))
            return groups
        else:
            new_Bf_dict = {
                p: trace
                for p, trace in Bf_dict.items()
                if trace.get(best_b, 0) > best_thd
            }
            logging.info(f"New group of {len(new_Bf_dict)} traces")
            trace_list_str = "\n".join([str(p) for p in new_Bf_dict.keys()])
            logging.debug(f"Traces are: {trace_list_str}")
            groups.append(list(new_Bf_dict.keys()))
            Bf_dict = {p: trace for p, trace in Bf_dict.items() if p not in new_Bf_dict}

    return groups


def preprocess_traces(paths: list[Path]) -> dict[Path, dict[str, int]]:
    """Read traces from files and count occurrences of addresses."""
    result: dict[Path, dict[str, int]] = {}

    logging.info(f"Preprocessing {len(paths)} trace files")
    for path in tqdm(paths):
        address_counts: dict[str, int] = {}

        with path.open("r", encoding="utf-8") as f:
            for raw_line in f:
                # New version with traces containing addresses and counts
                if not raw_line.strip():
                    # Skip empty lines
                    continue

                line_split = raw_line.split()
                if len(line_split) != 2:
                    continue

                addr = line_split[0]
                num = int(line_split[1])
                if addr in address_counts:
                    address_counts[addr] += num
                else:
                    address_counts[addr] = num

        if len(address_counts) == 0:
            logging.debug(f"File {path} is empty or does not contain any addresses")
            continue
        result[path] = address_counts

    return result


def store_groups(groups: list[list[Path]], output_dir: Path):
    """Store grouping as file tree."""
    output_dir.mkdir(parents=True, exist_ok=True)

    for idx, group in enumerate(groups):
        target = output_dir / f"{idx}"

        with target.open("w", encoding="utf-8") as f:
            for p in group:
                f.write(str(p) + "\n")


def default():
    """Deduplicate execution traces using mutual information."""
    parser = argparse.ArgumentParser(description="Default deduplication script")
    parser.add_argument(
        "-c", "--crash_dir", help="Path to directory of crashing traces", type=Path
    )
    parser.add_argument("-l", "--log_file", help="Path to log file", type=Path)
    parser.add_argument(
        "-n",
        "--non_crash_dir",
        help="Path to directory of non-crashing traces",
        type=Path,
    )
    parser.add_argument("-o", "--out_dir", help="Path to output directory", type=Path)
    args = parser.parse_args()

    crash_trace_dir = args.crash_dir
    non_crash_trace_dir = args.non_crash_dir
    output_dir = args.out_dir
    logfile = args.log_file
    if logfile is not None and logfile.is_file():
        logging.basicConfig(
            level=logging.INFO, filename=logfile, filemode="w", force=True
        )
    else:
        logging.basicConfig(stream=sys.stdout, level=logging.INFO, force=True)

    crash_trace_paths = crash_trace_dir.glob("**/*")
    crash_trace_paths = sorted(
        [
            trace_path.absolute()
            for trace_path in crash_trace_paths
            if trace_path.is_file()
        ]
    )
    non_crash_trace_paths = non_crash_trace_dir.glob("**/*")
    non_crash_trace_paths = sorted(
        [
            trace_path.absolute()
            for trace_path in non_crash_trace_paths
            if trace_path.is_file()
        ]
    )

    # List of crashing traces
    # Each trace is a dictionary with a starting address of a basic block
    # as a key and the number of occurrences of that basic block in the trace as
    # a value.
    Bf_dict: dict[Path, dict[str, int]] = preprocess_traces(crash_trace_paths)

    # List of non-crashing traces
    Bp_dict: dict[Path, dict[str, int]] = preprocess_traces(non_crash_trace_paths)

    groups = deduplication(Bf_dict, Bp_dict)
    logging.info(f"Number of deduplicated groups: {len(groups)}")
    store_groups(groups, output_dir)
    analyze_clustering_performance(groups, output_dir / "summary")


if __name__ == "__main__":
    default()
