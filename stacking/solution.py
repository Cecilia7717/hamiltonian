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
INPUT_DIR = STACKING_DIR / "stacking_examples_4"
OUTPUT_DIR = STACKING_DIR / "stacking_solution_4"

# ----------------------------
# Parsing
# ----------------------------
EXAMPLE_RE = re.compile(r"^Example\s+(\d+)\s*$")
TYPE_RE = re.compile(r"^(R\d+)\s+\((bottom|middle|top)\):\s+(C\d+)\s+—\s+(.+)$")
RECT_RE = re.compile(r"^\s*(R\d+)\s*:\s*m\s*=\s*(\d+)\s*,\s*n\s*=\s*(\d+)\s*$")


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
    if examples:
        required_keys = set(examples[0].keys())
        examples = [ex for ex in examples if set(ex.keys()) == required_keys]

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

def solve_one_example(rectangles):
    """
    rectangles: ordered list bottom -> top
                [(m1,n1), (m2,n2), ..., (mk,nk)]

    Returns list of solution chains.
    """

    k = len(rectangles)

    # Compute global y offsets
    y_offsets = []
    acc = 0
    for (m, n) in rectangles:
        y_offsets.append(acc)
        acc += n

    # Precompute endpoint maps
    maps = []
    for (m, n) in rectangles:
        maps.append(endpoint_map_top_to_bottom(m, n))

    solutions = []

    # Recursive propagation from TOP down
    def backtrack(level, chain):

        # level counts from top index down to 0
        if level < 0:
            solutions.append(chain.copy())
            return

        m, n = rectangles[level]
        mp = maps[level]

        if level == k - 1:
            # top rectangle: choose any start
            for x_s, ends in mp.items():
                for x_t in ends:
                    chain[level] = (x_s, x_t)
                    backtrack(level - 1, chain)
        else:
            # must match previous level's t
            x_s = chain[level + 1][1]
            if x_s not in mp:
                return

            for x_t in mp[x_s]:
                chain[level] = (x_s, x_t)
                backtrack(level - 1, chain)

    backtrack(k - 1, {})

    # Convert to global coordinate format
    formatted = []

    for sol in solutions:
        global_sol = {"x": {}, "global": {}}

        for i in range(k):
            m, n = rectangles[i]
            x_s, x_t = sol[i]

            y_off = y_offsets[i]
            y_start = y_off + (n - 1)
            y_end = y_off

            global_sol["x"][f"R{i+1}"] = (x_s, x_t)
            global_sol["global"][f"R{i+1}_s"] = (x_s, y_start)
            global_sol["global"][f"R{i+1}_t"] = (x_t, y_end)

        # whole stack endpoints
        global_sol["global"]["whole_s"] = global_sol["global"][f"R{k}_s"]
        global_sol["global"]["whole_t"] = global_sol["global"][f"R1_t"]

        formatted.append(global_sol)

    return formatted


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
        failed_examples = []
        for idx, ex in enumerate(examples, 1):
            rectangles = [ex[key] for key in sorted(ex.keys(), key=lambda x: int(x[1:]))]
            sols = solve_one_example(rectangles)
            if len(sols) == 0:
                failed_examples.append(idx)

            f.write(f"  #Solutions: {len(sols)}\n")
            if failed_examples:
                f.write("\n")
                f.write("============================================================\n")
                f.write("  EXAMPLES WITH NO VALID STACKING CHAINS:\n")
                for ex_id in failed_examples:
                    f.write(f"    - Example {ex_id}\n")
                f.write("============================================================\n")

            if sols:
                f.write("  Solutions (each line: R3[xs->xt], R2[xs->xt], R1[xs->xt])\n")
                for j, sol in enumerate(sols, 1):
                    for j, sol in enumerate(sols, 1):
                        f.write(f"    {j:3d}. ")
                        for i in range(len(rectangles), 0, -1):
                            xs, xt = sol["x"][f"R{i}"]
                            f.write(f"R{i}[{xs}->{xt}] ")
                        f.write("\n")


                f.write("\n  First few with global coordinates (up to 10 shown):\n")
                for j, sol in enumerate(sols[:10], 1):
                    g = sol["global"]
                    f.write(f"    {j:3d}. whole: s={g['whole_s']} -> t={g['whole_t']}\n")
                    for i in range(len(rectangles), 0, -1):
                        f.write(f"         R{i}: {g[f'R{i}_s']} -> {g[f'R{i}_t']}\n")

            f.write("\n" + ("-" * 60) + "\n\n")


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    txts = sorted(INPUT_DIR.glob("*.txt"))
    if not txts:
        raise FileNotFoundError(f"No .txt files found under {INPUT_DIR}")

    for in_file in txts:
        print(f"Processing: {in_file.name}")

        types, examples = parse_case_file(in_file)
        out_file = OUTPUT_DIR / in_file.name

        write_solutions(out_file, in_file, types, examples)

        print(f"  -> Wrote: {out_file}")

    print("\nAll files processed.")

if __name__ == "__main__":
    main()
