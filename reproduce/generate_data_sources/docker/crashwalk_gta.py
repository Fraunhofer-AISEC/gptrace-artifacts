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

"""Perform ground-truth analysis of deduplication results."""

from collections import defaultdict
import os
from pathlib import Path
from argparse import ArgumentParser
import subprocess as sp
import re
import pickle

CW_PATH = Path(__file__)
CWDUMP_PATH = CW_PATH.parent / "bin/cwdump"
CWFIND_PATH = CW_PATH.parent / "bin/cwfind"

NUM_DECIMAL_PLACES = 5

GT_ALL_TARGETS = {
    "freetype__char2svg": {
        "poc_D_raw": "poc_A_raw",
        "poc_G_raw": "poc_A_raw",
        "poc_H_raw": "poc_B_raw"
    },
    "libtiff__tiffcp": {
        "poc_CVE201610269_raw": ""
    },
    "libxml2__xmllint": {
        "poc_J_raw": "poc_I_raw"
    },
    "soxmp3__sox": {
        "poc_F_raw": "poc_E_raw"
    },
    "soxwav__sox": {
        "poc_D_raw": "poc_C_raw"
    }
}


def index_sets(result_list, gt_list):
    """Helper function for computing statistical metrics."""
    index_cluster = {}
    for cluster in set(result_list):
        index_cluster[cluster] = {n for n, x in enumerate(result_list) if x == cluster}

    index_bug = {}
    for bug in set(gt_list):
        index_bug[bug] = {n for n, x in enumerate(gt_list) if x == bug}

    return index_cluster, index_bug



def purity(result_list, gt_list, index_cluster, index_bug) -> float:
    """Compute purity."""
    purity = 0
    N = len(result_list)

    for i in set(result_list):
        # C_i
        C_i = result_list.count(i)
        index_cluster_i = index_cluster[i]

        maxP = 0
        # max_j P(C_i, L_j)
        for j in set(gt_list):
            index_bug_j = index_bug[j]

            # C_i \cap L_j
            intersection = len(index_cluster_i & index_bug_j)

            P = intersection / C_i
            if P > maxP:
                maxP = P

        purity += maxP * C_i / N

    return round(purity, NUM_DECIMAL_PLACES)


def inverse_purity(result_list, gt_list, index_cluster, index_bug) -> float:
    """Compute inverse purity."""
    inverse_purity = 0
    N = len(result_list)

    for i in set(gt_list):
        # L_i
        L_i = gt_list.count(i)
        index_bug_i = index_bug[i]

        maxP = 0
        # max_j P(L_i, C_j)
        for j in set(result_list):
            index_cluster_j = index_cluster[j]

            # L_i \cap C_j
            intersection = len(index_bug_i & index_cluster_j)

            P = intersection / L_i
            if P > maxP:
                maxP = P

        inverse_purity += maxP * L_i / N

    return round(inverse_purity, NUM_DECIMAL_PLACES)


def f_measure(result_list, gt_list, index_cluster, index_bug) -> float:
    """Compute F-measure."""
    f_measure = 0
    N = len(result_list)

    C_counts = {}
    for j in set(result_list):
        C_counts[j] = result_list.count(j)


    for i in set(gt_list):
        # L_i
        L_i = gt_list.count(i)
        index_bug_i = index_bug[i]

        maxF = 0
        # max_j F(L_i, C_j)
        for j in set(result_list):
            # C_j
            C_j = C_counts[j]
            index_cluster_j = index_cluster[j]

            # L_i \cap C_j
            intersection = len(index_bug_i & index_cluster_j)

            R = intersection / C_j
            P = intersection / L_i

            if R == 0 and P == 0:
                F = 0
            else:
                F = 2 * R * P / (R + P)

            if F > maxF:
                maxF = F

        f_measure += maxF * L_i / N

    return round(f_measure, NUM_DECIMAL_PLACES)


def statistical_scores(result_list, gt_list):
    """Compute purity, inverse purity and F-measure."""
    index_cluster, index_bug = index_sets(result_list, gt_list)

    p = purity(result_list, gt_list, index_cluster, index_bug)
    ip = inverse_purity(result_list, gt_list, index_cluster, index_bug)
    f = f_measure(result_list, gt_list, index_cluster, index_bug)

    return (p, ip, f)


def decimal_to_int_percentage(x: float) -> int:
    """Convert decimal value to integer percentage."""
    return int(100*x + 0.5)


def analyze_clustering_performance(label_dist, num_clusters, result_list, gt_list, round: bool):
    """Do ground-truth analysis."""
    unique_labels = {l for v in label_dist.values() for l in v.keys()}

    # Analyze undercounting (possibly losing bugs)
    uc = 0
    for l in unique_labels:
        bug_types_assigned_to_l = [bug_type for bug_type, clusters in label_dist.items() if l in clusters]
        if len(bug_types_assigned_to_l) > 1:
            uc += 1
            print(f"Undercounting present at cluster {l}: {bug_types_assigned_to_l}")

    # Analyze overcounting (more work triaging)
    overcounted = [(bug_type, len(clusters)) for bug_type, clusters in label_dist.items() if len(clusters) > 1]
    for oc in overcounted:
        print(f"Overcounting bug_type {oc[0]}: present in {oc[1]} clusters.")

    # Check for completely filtered/lost bugs
    cl = 0
    completely_lost = set()
    for b in label_dist.keys():
        clusters = label_dist[b]
        label_dist_without_self = {x: label_dist[x] for x in label_dist if x != b}
        if all([any([c in cs for cs in label_dist_without_self.values()]) for c in clusters]):
            cl += 1
            completely_lost.add(b)
            print(f"BUG {b} HAS NO DISTINCT CLUSTER. IT WILL BE LOST")

    p, ip, f = statistical_scores(result_list, gt_list)

    if round:
        p = decimal_to_int_percentage(p)
        ip = decimal_to_int_percentage(ip)
        f = decimal_to_int_percentage(f)

    ground_truth_results = {
        "num_clusters": num_clusters,
        "num_overcount": len(overcounted),
        "num_undercount": uc,
        "num_completely_lost": cl,
        "purity": p,
        "inverse_purity": ip,
        "f_measure": f,
    }

    return ground_truth_results


def get_gta_translation(translation_path):
    """Create translation table from generically renamed inputs to original file names that
    include ground-truth labeling."""

    target = ""
    for p in translation_path.parts:
        if p in GT_ALL_TARGETS:
            target = p

    gt = GT_ALL_TARGETS.get(target, {})

    with open(translation_path, "rb") as t:
        translation = pickle.load(t)
        gta_translation = {}
        ignored = []
        for f, i in translation.items():
            old_label = f.parent.name
            new_label = gt.get(old_label)
            if new_label is None:
                new_label = old_label
            if new_label == "":
                ignored.append(i)
                continue

            gta_translation[i] = f.parent.parent / new_label / f.name

    return gta_translation, ignored


def get_label_dist(labels, unique_file_paths, duplicates):
    """Get tables that contain clusters that are assigned to bug types and the clusters to
    which the SCIs are assigned."""
    label_dist = defaultdict(lambda: defaultdict(int))
    result_list = []
    gt_list = []

    for (k, f_path) in enumerate(unique_file_paths):
        bug_type = f_path.parent.name
        if bug_type == "":
            continue
        cluster = labels[k]
        label_dist[bug_type][cluster] += 1

        result_list.append(cluster)
        gt_list.append(bug_type)
        for d_path in duplicates[f_path]:
            bug_type = d_path.parent.name
            if bug_type == "":
                continue
            label_dist[bug_type][cluster] += 1
            result_list.append(cluster)
            gt_list.append(bug_type)
    return label_dist, result_list, gt_list


def prepare_vars(cwdb_path, gta_translation, ignored):
    """Parse Crashwalk database."""
    # Get list of hashes
    labels = []
    try:
        cwdump = sp.run([CWDUMP_PATH, cwdb_path], stdout=sp.PIPE).stdout.decode("utf-8")
    except sp.CalledProcessError:
        print("Call failed")
        exit(1)
    except Exception as e:
        print(f"Something else failed: {e}")
        exit(1)

    for line in cwdump.splitlines():
        if line.startswith("(1 of"):
            line = re.sub(r'^\(1 of [\d]+\) - Hash: ', '', line)
            labels.append(line)

    print("Collected all labels")
    if len(labels) != len(set(labels)):
        print("There seem to be duplicate hashes in the cwdump")
        exit(1)

    # For each hash, get one file path and store all duplicates
    unique_file_paths = []
    duplicates = dict()

    for hs in labels:
        try:
            cwfind = sp.run([CWFIND_PATH, "-db", cwdb_path, hs], stdout=sp.PIPE).stdout.decode("utf-8")
        except sp.CalledProcessError:
            print("Call failed")
            exit(1)
        except Exception as e:
            print(f"Something else failed: {e}")
            exit(1)
        unique_file = ""
        if len(cwfind.splitlines()) == 0:
            print("No files found for this hash")
            exit(1)
        for line in cwfind.splitlines():
            if gta_translation is not None:
                try:
                    file_path = gta_translation[Path(line)]
                except:
                    if Path(line) not in ignored:
                        print(f"Error finding trace associated to {line}")
                    continue
            else:
                file_path = Path(line)

            if unique_file == "":
                unique_file = file_path
                if unique_file != "":
                    unique_file_paths.append(unique_file)
                    duplicates[unique_file] = []
            else:
                duplicates[unique_file].append(file_path)

    return labels, unique_file_paths, duplicates


def parse_args():
    """Parse arguments."""
    parser = ArgumentParser()
    parser.add_argument(
        "cwdb_path",
        type=Path,
        help="Path to crashwalk database file",
    )
    parser.add_argument(
        "-t",
        "--translation",
        type=Path,
        help="Path to translation files; default: None",
        default=None
    )

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    if args.translation is not None:
        gta_translation, ignored = get_gta_translation(args.translation)
    else:
        gta_translation = None
        ignored = None

    labels, unique_file_paths, duplicates = prepare_vars(args.cwdb_path, gta_translation, ignored)
    label_dist, result_list, gt_list = get_label_dist(labels, unique_file_paths, duplicates)
    print(analyze_clustering_performance(label_dist, len(labels), result_list, gt_list, True))
