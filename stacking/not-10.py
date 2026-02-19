#!/usr/bin/env python3

from pathlib import Path
import re

# Adjust this if needed
STACKING_DIR = Path("/Users/cc/Desktop/hamiltonian/stacking")
INPUT_DIR = STACKING_DIR / "stacking_solution_4"

EXAMPLE_RE = re.compile(r"^Example\s+\d+\s*$")

def count_examples_in_file(path: Path) -> int:
    count = 0
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            if EXAMPLE_RE.match(line.strip()):
                count += 1
    return count


def main():
    txt_files = sorted(INPUT_DIR.glob("*.txt"))

    if not txt_files:
        print("No .txt files found.")
        return

    for file_path in txt_files:
        example_count = count_examples_in_file(file_path)

        if example_count != 10:
            print(f"{file_path.name}  ->  {example_count} examples")


if __name__ == "__main__":
    main()
