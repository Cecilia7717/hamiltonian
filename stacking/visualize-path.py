#!/usr/bin/env python3
"""
Read all stacking-case files under ./stacking_examples/
and generate one PDF per stacking-case under ./stacking_examples_visual/

For each input file:
- one output PDF
- for each Example:
    1) one base page showing the stacked rectangles
    2) one page per listed global-coordinate solution, drawing the exact
       points from lines like:
           R3: (0, 7) -> (0, 4)
           R2: (0, 3) -> (2, 2)
           R1: (2, 1) -> (8, 0)

This version parses the "First few with global coordinates" section.
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


# ----------------------------
# Config
# ----------------------------
INPUT_DIR = Path("stacking_examples")
OUTPUT_DIR = Path("stacking_examples_path_visual")


# ----------------------------
# Regex
# ----------------------------
EXAMPLE_RE = re.compile(r"^Example\s+(\d+)\s*$")
RECT_RE = re.compile(r"^\s*(R[123])\s*:\s*m\s*=\s*(\d+)\s*,\s*n\s*=\s*(\d+)\s*$")
NUM_SOL_RE = re.compile(r"^\s*#Solutions:\s*(\d+)\s*$")

COMPACT_SOL_RE = re.compile(
    r"^\s*\d+\.\s*"
    r"R3\[(\d+)->(\d+)\]\s*,\s*"
    r"R2\[(\d+)->(\d+)\]\s*,\s*"
    r"R1\[(\d+)->(\d+)\]\s*$"
)

WHOLE_RE = re.compile(
    r"^\s*(\d+)\.\s*whole:\s*s=\(([-]?\d+),\s*([-]?\d+)\)\s*->\s*t=\(([-]?\d+),\s*([-]?\d+)\)\s*$"
)

RECT_COORD_RE = re.compile(
    r"^\s*(R[123]):\s*\(([-]?\d+),\s*([-]?\d+)\)\s*->\s*\(([-]?\d+),\s*([-]?\d+)\)"
)


# ----------------------------
# Parsing
# ----------------------------
def parse_case_file(path: Path) -> List[Dict]:
    """
    Returns a list of examples.
    Each example has:
      {
        "index": int,
        "R1": (m1,n1),
        "R2": (m2,n2),
        "R3": (m3,n3),
        "num_solutions": int,
        "compact_solutions": [...],
        "global_solutions": [
            {
              "id": 1,
              "whole": {"s": (x,y), "t": (x,y)},
              "R1": {"s": (x,y), "t": (x,y)},
              "R2": {"s": (x,y), "t": (x,y)},
              "R3": {"s": (x,y), "t": (x,y)},
            },
            ...
        ]
      }
    """
    examples: List[Dict] = []
    current: Optional[Dict] = None

    in_compact_solutions = False
    in_global_solutions = False
    current_global_sol = None

    with path.open("r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.rstrip("\n")
            stripped = line.strip()

            m_ex = EXAMPLE_RE.match(stripped)
            if m_ex:
                if current is not None:
                    if current_global_sol is not None:
                        current["global_solutions"].append(current_global_sol)
                        current_global_sol = None
                    examples.append(current)

                current = {
                    "index": int(m_ex.group(1)),
                    "R1": None,
                    "R2": None,
                    "R3": None,
                    "num_solutions": 0,
                    "compact_solutions": [],
                    "global_solutions": [],
                }
                in_compact_solutions = False
                in_global_solutions = False
                current_global_sol = None
                continue

            if current is None:
                continue

            m_rect = RECT_RE.match(line)
            if m_rect:
                r, m_str, n_str = m_rect.group(1), m_rect.group(2), m_rect.group(3)
                current[r] = (int(m_str), int(n_str))
                continue

            m_num = NUM_SOL_RE.match(line)
            if m_num:
                current["num_solutions"] = int(m_num.group(1))
                continue

            if stripped.startswith("Solutions "):
                in_compact_solutions = True
                in_global_solutions = False
                continue

            if stripped.startswith("First few with global coordinates"):
                in_compact_solutions = False
                in_global_solutions = True
                if current_global_sol is not None:
                    current["global_solutions"].append(current_global_sol)
                    current_global_sol = None
                continue

            if in_compact_solutions:
                m_compact = COMPACT_SOL_RE.match(line)
                if m_compact:
                    xs3, xt3, xs2, xt2, xs1, xt1 = map(int, m_compact.groups())
                    current["compact_solutions"].append({
                        "R3": (xs3, xt3),
                        "R2": (xs2, xt2),
                        "R1": (xs1, xt1),
                    })
                continue

            if in_global_solutions:
                m_whole = WHOLE_RE.match(line)
                if m_whole:
                    if current_global_sol is not None:
                        current["global_solutions"].append(current_global_sol)

                    sol_id, sx, sy, tx, ty = map(int, m_whole.groups())
                    current_global_sol = {
                        "id": sol_id,
                        "whole": {"s": (sx, sy), "t": (tx, ty)},
                    }
                    continue

                m_rect_coord = RECT_COORD_RE.match(line)
                if m_rect_coord and current_global_sol is not None:
                    r, sx, sy, tx, ty = m_rect_coord.groups()
                    current_global_sol[r] = {
                        "s": (int(sx), int(sy)),
                        "t": (int(tx), int(ty)),
                    }
                    continue

    if current is not None:
        if current_global_sol is not None:
            current["global_solutions"].append(current_global_sol)
        examples.append(current)

    cleaned = []
    for ex in examples:
        if all(ex[k] is not None for k in ("R1", "R2", "R3")):
            cleaned.append(ex)
    return cleaned


# ----------------------------
# Drawing helpers
# ----------------------------
def draw_grid(ax, m: int, n: int, x0: int, y0: int, linewidth: float = 1.0):
    for x in range(m + 1):
        ax.plot([x0 + x, x0 + x], [y0, y0 + n], color="black", lw=linewidth)
    for y in range(n + 1):
        ax.plot([x0, x0 + m], [y0 + y, y0 + y], color="black", lw=linewidth)


def draw_point(ax, p, label, marker="o", text_dx=0.12, text_dy=0.12, size=70):
    x, y = p
    ax.scatter([x], [y], s=size, marker=marker, color="black", zorder=5)
    ax.text(x + text_dx, y + text_dy, label, fontsize=10, zorder=6)


def setup_axes(ax, m1, n1, m2, n2, m3, n3):
    total_h = n1 + n2 + n3
    max_w = max(m1, m2, m3)
    ax.set_aspect("equal")
    ax.set_xlim(-0.8, max_w + 5.0)
    ax.set_ylim(-0.8, total_h + 1.2)
    ax.axis("off")


def draw_rectangles_only(ax, m1, n1, m2, n2, m3, n3):
    y1 = 0
    y2 = y1 + n1
    y3 = y2 + n2

    draw_grid(ax, m1, n1, 0, y1)
    draw_grid(ax, m2, n2, 0, y2)
    draw_grid(ax, m3, n3, 0, y3)

    ax.text(m1 + 0.4, y1 + n1 / 2, f"R1\nm={m1}, n={n1}", va="center", fontsize=11)
    ax.text(m2 + 0.4, y2 + n2 / 2, f"R2\nm={m2}, n={n2}", va="center", fontsize=11)
    ax.text(m3 + 0.4, y3 + n3 / 2, f"R3\nm={m3}, n={n3}", va="center", fontsize=11)

    setup_axes(ax, m1, n1, m2, n2, m3, n3)


def draw_global_solution(ax, m1, n1, m2, n2, m3, n3, sol):
    y1 = 0
    y2 = y1 + n1
    y3 = y2 + n2

    draw_grid(ax, m1, n1, 0, y1)
    draw_grid(ax, m2, n2, 0, y2)
    draw_grid(ax, m3, n3, 0, y3)

    ax.text(m1 + 0.4, y1 + n1 / 2, f"R1\nm={m1}, n={n1}", va="center", fontsize=11)
    ax.text(m2 + 0.4, y2 + n2 / 2, f"R2\nm={m2}, n={n2}", va="center", fontsize=11)
    ax.text(m3 + 0.4, y3 + n3 / 2, f"R3\nm={m3}, n={n3}", va="center", fontsize=11)

    # draw rectangle-level s,t directly from global coordinates
    for rect_name in ["R3", "R2", "R1"]:
        if rect_name in sol:
            s = sol[rect_name]["s"]
            t = sol[rect_name]["t"]
            draw_point(ax, s, f"{rect_name} s", marker="o", text_dx=0.10, text_dy=0.14, size=70)
            draw_point(ax, t, f"{rect_name} t", marker="x", text_dx=0.10, text_dy=-0.22, size=90)

    # dashed bridges between rectangle endpoints
    if "R3" in sol and "R2" in sol:
        x1, y1_ = sol["R3"]["t"]
        x2, y2_ = sol["R2"]["s"]
        ax.plot([x1, x2], [y1_, y2_], linestyle="--", lw=1.2, color="gray")

    if "R2" in sol and "R1" in sol:
        x1, y1_ = sol["R2"]["t"]
        x2, y2_ = sol["R1"]["s"]
        ax.plot([x1, x2], [y1_, y2_], linestyle="--", lw=1.2, color="gray")

    # whole start/end if present
    if "whole" in sol:
        ws = sol["whole"]["s"]
        wt = sol["whole"]["t"]
        draw_point(ax, ws, "whole s", marker="s", text_dx=0.12, text_dy=0.18, size=80)
        draw_point(ax, wt, "whole t", marker="D", text_dx=0.12, text_dy=-0.28, size=80)

    setup_axes(ax, m1, n1, m2, n2, m3, n3)


# ----------------------------
# PDF writer
# ----------------------------
def write_case_pdf(case_txt_path: Path, out_pdf_path: Path):
    examples = parse_case_file(case_txt_path)
    if not examples:
        return

    out_pdf_path.parent.mkdir(parents=True, exist_ok=True)

    with PdfPages(out_pdf_path) as pdf:
        for ex in examples:
            (m1, n1) = ex["R1"]
            (m2, n2) = ex["R2"]
            (m3, n3) = ex["R3"]

            # base page
            fig = plt.figure(figsize=(8.5, 11))
            ax = fig.add_subplot(111)
            fig.suptitle(
                f"{case_txt_path.stem} — Example {ex['index']} (base layout)",
                fontsize=14,
                y=0.98,
            )
            draw_rectangles_only(ax, m1, n1, m2, n2, m3, n3)
            pdf.savefig(fig)
            plt.close(fig)

            # exact global-coordinate pages
            if ex["global_solutions"]:
                for sol in ex["global_solutions"]:
                    fig = plt.figure(figsize=(8.5, 11))
                    ax = fig.add_subplot(111)

                    title_lines = [
                        f"{case_txt_path.stem} — Example {ex['index']} — Global solution {sol['id']}"
                    ]

                    if "R3" in sol and "R2" in sol and "R1" in sol:
                        r3s, r3t = sol["R3"]["s"], sol["R3"]["t"]
                        r2s, r2t = sol["R2"]["s"], sol["R2"]["t"]
                        r1s, r1t = sol["R1"]["s"], sol["R1"]["t"]
                        title_lines.append(
                            f"R3: {r3s}->{r3t}   R2: {r2s}->{r2t}   R1: {r1s}->{r1t}"
                        )

                    fig.suptitle("\n".join(title_lines), fontsize=12, y=0.98)

                    draw_global_solution(ax, m1, n1, m2, n2, m3, n3, sol)

                    pdf.savefig(fig)
                    plt.close(fig)


# ----------------------------
# Main
# ----------------------------
def main():
    if not INPUT_DIR.exists():
        raise FileNotFoundError(f"Input folder not found: {INPUT_DIR.resolve()}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    txt_files = sorted(INPUT_DIR.glob("*.txt"))
    if not txt_files:
        print(f"No .txt files found under {INPUT_DIR.resolve()}")
        return

    for txt_path in txt_files:
        out_pdf = OUTPUT_DIR / f"{txt_path.stem}.pdf"
        write_case_pdf(txt_path, out_pdf)
        print(f"Wrote: {out_pdf}")

    print(f"Done. PDFs written to: {OUTPUT_DIR.resolve()}")


if __name__ == "__main__":
    main()