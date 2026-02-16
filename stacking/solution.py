#!/usr/bin/env python3
"""
Solve one stacking-case file by propagating endpoint constraints (no path enumeration).

INPUT (one file):
  /Users/cc/Desktop/hamiltonian/stacking/stacking_examples/<case>.txt

OUTPUT (one file):
  /Users/cc/Desktop/hamiltonian/stacking/stacking_solution/<case>.txt

What it does for each Example:
  1) For R3 (top rectangle), generate all possible start points s3 (on TOP boundary)
     and their allowed end points t3 (on BOTTOM boundary), using theorem_allows_path(m,n,x1,x2).
  2) For each t3 at x=x2, the only adjacent vertex below is the TOP boundary vertex of R2
     at the same x. That becomes candidate s2 (must be feasible in R2).
  3) Repeat to R1.
  4) Record every valid chain:
        R3: s3 -> t3
        R2: s2 -> t2
        R1: s1 -> t1
     and also the global endpoints of the whole stacked graph: s3 (global) -> t1 (global).

Coordinate convention (important):
  - Each rectangle Ri has local coordinates:
      x in [0..m-1], y in [0..n-1], with y=0 the BOTTOM row.
  - We FORCE starts to be on TOP boundary (y=n-1) and ends on BOTTOM boundary (y=0),
    because your stacking step says: "s_(i-1) is the point right below each possible ending point of Ri".
  - Global y-offsets:
      R1: y_offset = 0
      R2: y_offset = n1
      R3: y_offset = n1 + n2

Usage:
  python3 stacking_solve_one_file.py
    -> solves the first .txt under stacking_examples (alphabetical)

  python3 stacking_solve_one_file.py /path/to/specific_case.txt
    -> solves that file
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# ----------------------------
# Paths (you can edit if needed)
# ----------------------------
STACKING_DIR = Path("/Users/cc/Desktop/hamiltonian/stacking")
INPUT_DIR = STACKING_DIR / "stacking_examples"
OUTPUT_DIR = STACKING_DIR / "stacking_solution"

# ----------------------------
# Parsing
# ----------------------------
TYPE_RE = re.compile(r"^(R[123])\s+\((bottom|middle|top)\):\s+(C\d+)\s+—\s+(.+)$")
EXAMPLE_RE = re.compile(r"^Example\s+(\d+)\s*$")
RECT_RE = re.compile(r"^\s*(R[123])\s*:\s*m\s*=\s*(\d+)\s*,\s*n\s*=\s*(\d+)\s*$")


def parse_case_file(path: Path):
    """
    Returns:
      types: dict like {"R1": ("C2", "m even > 2, n = 2"), ...}
      examples: list of dicts: {"R1": (m1,n1), "R2": (m2,n2), "R3": (m3,n3)}
    """
    types: Dict[str, Tuple[str, str]] = {}
    examples: List[Dict[str, Tuple[int, int]]] = []
    cur: Dict[str, Tuple[int, int]] = {}

    with path.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")

            mtype = TYPE_RE.match(line.strip())
            if mtype:
                r = mtype.group(1)
                c = mtype.group(3)
                desc = mtype.group(4)
                types[r] = (c, desc)
                continue

            mex = EXAMPLE_RE.match(line.strip())
            if mex:
                if cur:
                    examples.append(cur)
                    cur = {}
                continue

            mrect = RECT_RE.match(line)
            if mrect:
                r = mrect.group(1)
                m = int(mrect.group(2))
                n = int(mrect.group(3))
                cur[r] = (m, n)
                continue

    if cur:
        examples.append(cur)

    # keep only complete examples
    examples = [ex for ex in examples if all(k in ex for k in ("R1", "R2", "R3"))]
    return types, examples


# ----------------------------
# Your theorem checker (as provided)
# ----------------------------
def theorem_allows_path(m, n, x1, x2):
    if m % 2 == 0:
        if m == 2:
            if n % 2 == 1:
                return (x1, x2) in [(0, 1), (1, 0)]
            else:
                return (x1, x2) in [(0, 0), (1, 1)]
        else:
            if n % 2 == 0:
                if n == 2:
                    return (
                        (x1 % 2 == x2 % 2)
                        and (
                            (x1 != x2)
                            or (x1 == x2 == 0)
                            or (x1 == x2 == m - 1)
                        )
                    )
                else:
                    return x1 % 2 == x2 % 2
            else:
                # ---------- n odd ----------
                if n == 3:
                    # parity condition
                    if x1 % 2 == x2 % 2:
                        return False

                    A = {0, 2, m - 3, m - 1}
                    if x1 in A:
                        return True

                    even_index = list(range(2, m, 2))      # {2,4,...,m-2}
                    odd_index  = list(range(1, m - 4, 2))  # {1,3,...,m-5}

                    if x1 % 2 == 1:
                        # x1 odd
                        k = (x1 + 1) // 2
                        forbidden = even_index[k:]
                        return x2 not in forbidden
                    else:
                        # x1 even
                        k = (m - 2 - x1) // 2
                        forbidden = odd_index[:len(odd_index) - k]
                        return x2 not in forbidden
                else:
                    return x1 % 2 != x2 % 2
    else:
        if m == 3:
            return (x1, x2) in [
                (0, 0),
                (m - 1, 0),
                (0, m - 1),
                (m - 1, m - 1),
            ]
        else:
            if n % 2 == 0:
                if n == 2:
                    return (
                        (x1 % 2 == x2 % 2)
                        and (
                            (x1 != x2)
                            or (x1 == x2 == 0)
                            or (x1 == x2 == m - 1)
                        )
                    )
                else:
                    return x1 % 2 == x2 % 2
            else:
                return (
                    x1 % 2 == 0
                    and x2 % 2 == 0
                )


# ----------------------------
# Endpoint generation (start on TOP, end on BOTTOM)
# ----------------------------
def endpoint_map_top_to_bottom(m: int, n: int) -> Dict[int, List[int]]:
    """
    Returns mapping:
      start_x  -> list of end_x
    where:
      start point is (start_x, y=n-1)
      end point   is (end_x,   y=0)
    """
    mp: Dict[int, List[int]] = {}
    for x1 in range(m):
        ends = []
        for x2 in range(m):
            if theorem_allows_path(m, n, x1, x2):
                ends.append(x2)
        if ends:
            mp[x1] = ends
    return mp


# ----------------------------
# Solve one example
# ----------------------------
def solve_one_example(m1, n1, m2, n2, m3, n3):
    """
    Returns list of solution chains.
    Each chain is a dict with:
      s3,t3,s2,t2,s1,t1 as GLOBAL coordinates (x,y)
      plus x-only summary.
    """
    # Global y offsets
    y1_off = 0
    y2_off = n1
    y3_off = n1 + n2

    # Start (top boundary) y values
    y1_start = y1_off + (n1 - 1)
    y2_start = y2_off + (n2 - 1)
    y3_start = y3_off + (n3 - 1)

    # End (bottom boundary) y values
    y1_end = y1_off + 0
    y2_end = y2_off + 0
    y3_end = y3_off + 0

    # Maps: start_x -> end_xs
    M1 = endpoint_map_top_to_bottom(m1, n1)
    M2 = endpoint_map_top_to_bottom(m2, n2)
    M3 = endpoint_map_top_to_bottom(m3, n3)

    solutions = []

    # R3 choices
    for x_s3, ends3 in M3.items():
        for x_t3 in ends3:
            # adjacency down into R2:
            # t3 at (x_t3, y3_end) has below neighbor at (x_t3, y3_end - 1)
            # which is exactly the TOP boundary of R2 at y2_start
            # so we must have s2.x = x_t3
            x_s2 = x_t3
            if x_s2 not in M2:
                continue

            # R2 choices
            for x_t2 in M2[x_s2]:
                # adjacency down into R1:
                x_s1 = x_t2
                if x_s1 not in M1:
                    continue

                # R1 choices
                for x_t1 in M1[x_s1]:
                    sol = {
                        "x": {
                            "R3": (x_s3, x_t3),
                            "R2": (x_s2, x_t2),
                            "R1": (x_s1, x_t1),
                        },
                        "global": {
                            "R3_s": (x_s3, y3_start),
                            "R3_t": (x_t3, y3_end),
                            "R2_s": (x_s2, y2_start),
                            "R2_t": (x_t2, y2_end),
                            "R1_s": (x_s1, y1_start),
                            "R1_t": (x_t1, y1_end),
                            "whole_s": (x_s3, y3_start),
                            "whole_t": (x_t1, y1_end),
                        }
                    }
                    solutions.append(sol)

    return solutions


# ----------------------------
# Pretty output
# ----------------------------
def write_solutions(out_path: Path, in_path: Path, types, examples, only_first_file=True):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with out_path.open("w", encoding="utf-8") as f:
        f.write(f"INPUT FILE: {in_path}\n\n")

        f.write("Stacking Case (types read from header)\n")
        f.write("-------------------------------------\n")
        for r in ("R1", "R2", "R3"):
            if r in types:
                c, desc = types[r]
                f.write(f"{r}: {c} — {desc}\n")
            else:
                f.write(f"{r}: (missing type header)\n")
        f.write("\n")

        for idx, ex in enumerate(examples, 1):
            (m1, n1) = ex["R1"]
            (m2, n2) = ex["R2"]
            (m3, n3) = ex["R3"]

            f.write(f"Example {idx}\n")
            f.write(f"  R1: m={m1}, n={n1}\n")
            f.write(f"  R2: m={m2}, n={n2}\n")
            f.write(f"  R3: m={m3}, n={n3}\n")

            sols = solve_one_example(m1, n1, m2, n2, m3, n3)
            f.write(f"  #Solutions: {len(sols)}\n")

            if sols:
                f.write("  Solutions (each line: R3[xs->xt], R2[xs->xt], R1[xs->xt])\n")
                for j, sol in enumerate(sols, 1):
                    xR3 = sol["x"]["R3"]
                    xR2 = sol["x"]["R2"]
                    xR1 = sol["x"]["R1"]
                    f.write(f"    {j:3d}. R3[{xR3[0]}->{xR3[1]}], R2[{xR2[0]}->{xR2[1]}], R1[{xR1[0]}->{xR1[1]}]\n")

                f.write("\n  First few with global coordinates (up to 10 shown):\n")
                for j, sol in enumerate(sols[:10], 1):
                    g = sol["global"]
                    f.write(f"    {j:3d}. whole: s={g['whole_s']} -> t={g['whole_t']}\n")
                    f.write(f"         R3: {g['R3_s']} -> {g['R3_t']}   (bridge down from R3_t to R2_s)\n")
                    f.write(f"         R2: {g['R2_s']} -> {g['R2_t']}   (bridge down from R2_t to R1_s)\n")
                    f.write(f"         R1: {g['R1_s']} -> {g['R1_t']}\n")
            f.write("\n" + ("-" * 60) + "\n\n")


def pick_one_input_file(argv: List[str]) -> Path:
    if len(argv) >= 2:
        p = Path(argv[1])
        if not p.exists():
            raise FileNotFoundError(f"File not found: {p}")
        return p

    # default: first .txt alphabetically
    txts = sorted(INPUT_DIR.glob("*.txt"))
    if not txts:
        raise FileNotFoundError(f"No .txt files found under {INPUT_DIR}")
    return txts[98]


def main():
    in_file = pick_one_input_file(sys.argv)
    types, examples = parse_case_file(in_file)

    out_file = OUTPUT_DIR / in_file.name  # same name, different folder
    write_solutions(out_file, in_file, types, examples)

    print(f"Done. Wrote: {out_file}")


if __name__ == "__main__":
    main()
