#!/usr/bin/env python3
"""
Read all stacking-case files under ./stacking_examples/
and generate one PDF per stacking-case under ./stacking_examples_visual/
Each PDF contains up to 10 examples (one per page) showing the 3 stacked rectangles.

Usage:
  python3 visualize_stacking_examples.py

Assumptions about input format (matches your generator):
- Files are .txt
- Each contains blocks like:
    Example k
      R1: m=..., n=...
      R2: m=..., n=...
      R3: m=..., n=...

Output:
  stacking_examples_visual/<same_base_name>.pdf
"""

import os
import re
from pathlib import Path
from typing import Dict, List, Tuple

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


# ----------------------------
# Config
# ----------------------------
INPUT_DIR = Path("stacking_examples")
OUTPUT_DIR = Path("stacking_examples_visual")
MAX_EXAMPLES_PER_CASE = 10  # expected 10, but we handle fewer safely


# ----------------------------
# Parsing
# ----------------------------
EXAMPLE_RE = re.compile(r"^Example\s+(\d+)\s*$")
RECT_RE = re.compile(r"^\s*(R[123])\s*:\s*m\s*=\s*(\d+)\s*,\s*n\s*=\s*(\d+)\s*$")


def parse_case_file(path: Path) -> List[Dict[str, Tuple[int, int]]]:
    """
    Return a list of examples.
    Each example is a dict: {"R1": (m1,n1), "R2": (m2,n2), "R3": (m3,n3)}
    """
    examples: List[Dict[str, Tuple[int, int]]] = []
    current: Dict[str, Tuple[int, int]] = {}

    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")

            m_ex = EXAMPLE_RE.match(line.strip())
            if m_ex:
                # Starting a new example: push previous if complete
                if current:
                    examples.append(current)
                    current = {}
                continue

            m_rect = RECT_RE.match(line)
            if m_rect:
                r, m_str, n_str = m_rect.group(1), m_rect.group(2), m_rect.group(3)
                current[r] = (int(m_str), int(n_str))

    # push last
    if current:
        examples.append(current)

    # Keep only those that have R1,R2,R3
    examples = [ex for ex in examples if all(k in ex for k in ("R1", "R2", "R3"))]
    return examples[:MAX_EXAMPLES_PER_CASE]


# ----------------------------
# Drawing
# ----------------------------
def draw_grid(ax, m: int, n: int, x0: int, y0: int, linewidth: float = 1.0):
    """Draw an m-by-n cell grid with bottom-left corner at (x0,y0)."""
    # vertical lines
    for x in range(m + 1):
        ax.plot([x0 + x, x0 + x], [y0, y0 + n], lw=linewidth)
    # horizontal lines
    for y in range(n + 1):
        ax.plot([x0, x0 + m], [y0 + y, y0 + y], lw=linewidth)


def render_one_example_pdf_page(
    ax,
    m1: int, n1: int,
    m2: int, n2: int,
    m3: int, n3: int,
):
    """
    Render 3 stacked rectangles with left edges aligned:
      bottom R1 (m1,n1), middle R2 (m2,n2), top R3 (m3,n3)
    """
    # y offsets for stacking
    y1 = 0
    y2 = y1 + n1
    y3 = y2 + n2

    # draw grids
    draw_grid(ax, m1, n1, x0=0, y0=y1)
    draw_grid(ax, m2, n2, x0=0, y0=y2)
    draw_grid(ax, m3, n3, x0=0, y0=y3)

    # labels
    ax.text(m1 + 0.3, y1 + n1 / 2, f"R1\nm={m1}, n={n1}", va="center")
    ax.text(m2 + 0.3, y2 + n2 / 2, f"R2\nm={m2}, n={n2}", va="center")
    ax.text(m3 + 0.3, y3 + n3 / 2, f"R3\nm={m3}, n={n3}", va="center")

    # formatting
    total_h = n1 + n2 + n3
    max_w = max(m1, m2, m3)

    ax.set_aspect("equal")
    ax.set_xlim(-0.5, max_w + 4.5)   # extra space for labels on right
    ax.set_ylim(-0.5, total_h + 0.5)
    ax.axis("off")


def write_case_pdf(case_txt_path: Path, out_pdf_path: Path):
    examples = parse_case_file(case_txt_path)
    if not examples:
        return

    out_pdf_path.parent.mkdir(parents=True, exist_ok=True)

    with PdfPages(out_pdf_path) as pdf:
        for idx, ex in enumerate(examples, 1):
            (m1, n1) = ex["R1"]
            (m2, n2) = ex["R2"]
            (m3, n3) = ex["R3"]

            fig = plt.figure(figsize=(8.5, 11))
            ax = fig.add_subplot(111)

            fig.suptitle(
                f"{case_txt_path.stem} — Example {idx}",
                fontsize=14,
                y=0.98
            )

            render_one_example_pdf_page(ax, m1, n1, m2, n2, m3, n3)

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
        print(f"No .txt files found under {INPUT_DIR}/")
        return

    for txt_path in txt_files:
        out_pdf = OUTPUT_DIR / f"{txt_path.stem}.pdf"
        write_case_pdf(txt_path, out_pdf)

    print(f"Done. PDFs written to: {OUTPUT_DIR.resolve()}")


if __name__ == "__main__":
    main()
